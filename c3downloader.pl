#!/usr/local/bin/perl

# LWP::Simple lets us download pages
# JSON::Parse lets us convert JSON structures into Perl structures
# Parallel::ForkManager makes it easier for us to do multiple downloads at a time
use Parallel::ForkManager;
use LWP::Simple;
use JSON::Parse ('valid_json', 'parse_json');

use strict;
use warnings;

# Convert date strings into something comparable
# This just removes anything that isn't a number from the date string so that they can be numerically compared.
# In this format, the greater number is always the more recent of the two.
sub comparable
{
    my $str = shift;

    $str =~ s/[^\d]//g;  
    # Dates are supposed to be in YYYY-MM-DD HH:MI:SS
    # But ReleasedOn tends to be just a date with no time, so we'll append some zeroes.
    $str .= "000000" if ( length ($str) == 8 );

    return $str;
}


# Vars
my $song_count = 2000; # Fetch this many songs on a single page. Basically, set this high enough that you get everything.
my $sort_by = "ReleasedOn";
my $sort_direction = "DESC";
my $url = "http://pksage.com/songlist/php/songlist.php?_dc=1443067770349&whichGame=rb&andor=&page=1&start=0&limit=$song_count&sort=%5B%7B%22property%22%3A%22$sort_by%22%2C%22direction%22%3A%22$sort_direction%22%7D%5D&filter=%5B%7B%22property%22%3A%22Source%22%2C%22value%22%3A%22Custom%20Songs%7Cis%22%7D%5D";
my $dl_prefix = "http://keepitfishy.com/";
my $last_update_file = "last_update.txt";
my $last_update_time = "1969-12-31 23:59:59";
my $con_dir = "Cons/C3"; # Should be relative. Must not have trailing /
my %downloads;  # This hash will be $downloads{'FileName'} = 'DownloadURL'
my $start_time = time;
my $most_recent = '1970-01-01 01:01:01';    # This will store the most recent Release Date or Update Date
my $max_concurrent_downloads = 4;   # How many files should we download at once?

# Last-Update file
# This file just contains a date/time on a single line that gives this script a reference point
# so it can do incremental updates. Without this file the script downloads the entire repository.
if ( -e $last_update_file )
{
    open my $in, $last_update_file or die("Could not open $last_update_file!\n");
    $last_update_time = <$in>;
    chomp $last_update_time;
    close $in;

    print localtime(time) . ": Found last update on $last_update_time. Only looking for new files and updates since then.\n";
}
else
{
    print localtime(time) . ": No Update File found. This will trigger a full DB download.\n";
}


# Fetch the raw JSON data that C3's jquery grid table dresses up
print localtime(time) . ": Fetching raw JSON data...\n";
my $json = get($url);

die("Unable to retrieve Song List from C3!\n\nDied") unless defined $json;

# Check to make sure the JSON is valid.
print localtime(time) . ": Validating JSON structure...\n";
unless( valid_json($json) )
{
    print "Invalid JSON:\n-----------\n\n$json\n\n-------\n";
    die("Unable to parse JSON Song List\n\nDied") unless valid_json ($json);
}

# Now convert the JSON into a Perl HASH structure.
print localtime(time) . ": Parsing JSON structure...\n";
my $table = parse_json($json);

die("JSON call failed\n\nDied") unless $table->{'success'};

# How many entries does the server report?
print localtime(time) . ": Parsing " . $table->{'total'} . " song entries\n";

# For each entry, collect some info and determine the "Real" download url
# The download link in the JSON array just takes you to another page that contains the real link in some JS.
# We need to extract that for the downloads.
foreach my $entry ( @{$table->{'data'}} )
{
    # The download link here is not the actual D/L, it's just a link to a page that has it.
    my $download_page = get($entry->{'CustomDownloadURL'});

    if ( !defined($download_page) )
    {
        print localtime(time) . ": Skipping '" . $entry->{'FullName'} . "' (No download link available)\n";
        next;
    }
    
    my $released = $entry->{'ReleasedOn'};
    my $updated = ( defined $entry->{'UpdatedOn'} ? $entry->{'UpdatedOn'} : 0 );
    print "\tUpdated: $updated // Released: $released\n";

    # Which is more recent? The Release Date or Update Date?
    # Update Date will be, but only if it is defined. So check them both.
    my $max = comparable($updated) > comparable($released) ? $updated : $released;

    # Now is this time the most recent timestamp in the entire batch?
    # If so, capture it.
    $most_recent = $max if comparable($max) > comparable($most_recent);

    # Compare the UpdatedOn and ReleasedOn fields for this entry against the most recent update last time this script ran.
    # If the song is newer, queue it for download. 
    # Otherwise skip over it.
    if ( comparable($released) > comparable($last_update_time) or comparable($updated) > comparable($last_update_time) )
    {
        # Grab the real download link from the download page
        my ($real_download) = $download_page =~ /URL=(.+)"/; # So hacky. Oh well.

        if ( !defined($real_download) )
        {
            print localtime(time) . ": Skipping '" . $entry->{'FullName'} . "' (Could not find the real download link)\n";
            next;
        }

        # The Base Name is the filename without any directory structure included.
        # eg, "/stuff/things/file.mp3" has a basename of "file.mp3"
        my ($base_name) = $real_download =~ /^.*\/(.+$)/;

        print localtime(time) . ": Queued '" . $entry->{'FullName'} . "' for download.\n";
        $downloads{$base_name} = $dl_prefix . $real_download;
    }
    elsif ( comparable($released) <= comparable($last_update_time) and comparable($updated) <= comparable($last_update_time) )
    {
        print comparable($released) . " <= " . comparable($last_update_time) . " AND " . comparable($updated) . " <= " . comparable($last_update_time) . "\n";
        print localtime(time) . ": Skipping '" . $entry->{'FullName'} . "' as it has not changed since last time.\n";
    }
    else
    {
        print localtime(time) . ": Skipping '" . $entry->{'FullName'} . "' for reasons unknown..\n";
    }
}

# So now we have a list of downloads. Let's do it!
my $num_downloads = scalar (keys %downloads);

print localtime(time) . ": $num_downloads files queued for download.\n";

print localtime(time) . ": Checking local files.\n";

# Check to see if the file exists locally already.
# This way users who want to fill out their collection with missing files can do so
# without having to re-download their existing files.
# It also provides a way to "resume" a crashed or failed run and try again.
foreach my $key ( keys %downloads )
{
    if ( -f $con_dir . '/' . $key )
    {
        print localtime(time) . ": File '$key' already exists! Removing it from the download queue.\n"; 
        delete $downloads{$key};
    }    
}

# If we removed any queued downloads due to existing local files, print the new total to the screen
# and update the num_downloads variable.
if ( scalar (keys %downloads) != $num_downloads )
{
    $num_downloads = scalar (keys (%downloads));
    print localtime(time) . ": $num_downloads downloads remain.\n";
}

# Parallel Manager
my $pm = Parallel::ForkManager->new($max_concurrent_downloads);

my $i = 0;
LINKS:
foreach my $key ( keys (%downloads) )
{
    $i++;
    $pm->start and next LINKS; # Fork

    my $msg = sprintf("[%04s / %04s] Downloading %s", $i, $num_downloads, $key);
    print localtime(time) . ": $msg\n";
    getstore($downloads{$key}, $con_dir . '/' . $key);

    $pm->finish; # Exit the child process
}
$pm->wait_all_children; # Wait for all downloads to finish before continuing

# Finally, if we've made it this far we can update the last_update_file
print localtime(time) . ": New 'Last Update' time: $most_recent\n";

# Now write that time out to a file for next session.
open my $out, ">$last_update_file";
print $out $most_recent;
close $out;

print localtime(time) . ": Complete!\n";
