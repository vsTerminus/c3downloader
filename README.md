C3 Downloader is a simple Perl script written to function as a batch downloader for Rock Band 3 Custom tracks on http://db.customscreators.com/

It downloads four files at a time in parallel. Hopefully this finds a balance between runtime and server strain.

By writing to a "last_update.txt" file when it completes, the script is aware of which files are new or updated since the last time you ran it.
This file can be modified by hand if you want to force the script to go through the entire DB for songs you don't have. You can also modify the timestamp to customize the range of this behavior.

Downloaded files are saved to the ./Cons/C3/ folder, relative to wherever you are running the script from.
If you have existing con files from C3, put them in this directory and the script will skip over them instead of re-downloading.

INSTALL:

    - Requires perl, obviously. 
    - Install the following CPAN modules (preferably using cpanminus)
        - JSON::Parse
        - LWP::Simple
        - Mojo::UserAgent
        - Mojo::IOLoop
        - File::Basename
    - Create the "Cons" and "Cons/C3" folders, as the script will not try to create them for you
        - mkdir -p Cons/C3

RUN:

    - Run the .pl file
        - perl c3downloader.pl
