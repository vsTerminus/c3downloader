C3 Downloader is a simple Perl script written to function as a batch downloader for Rock Band 3 Custom tracks on http://db.customscreators.com/

It downloads only one file at a time to be as easy on the server as possible.

By writing to a "last_update.txt" file when it completes, the script is aware of which files are new or updated since the last time you ran it.
This file can be modified by hand if you want to force the script to re-download a wider date-range.

Downloaded files are saved to the ./cons/c3/ folder, relative to wherever you are running the script from.
If you have existing con files from C3, put them in this directory and the script will skip over them instead of re-downloading.

INSTALL:

    - Script requires JSON::Parse and LWP::Simple to function.
    - Create the "cons" and "cons/c3" folders, as the script will not try to create them

RUN:

    - Run the file with: perl c3downloader.pl
