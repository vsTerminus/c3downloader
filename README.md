C3 Downloader is a simple Perl script written to function as a batch downloader for Rock Band 3 Custom tracks on http://db.customscreators.com/

It downloads six files at a time in parallel. Hopefully this finds a balance between runtime and server strain.

By writing to a "last_update.txt" file when it completes, the script is aware of which files are new or updated since the last time you ran it.
This file can be modified by hand if you want to force the script to go through the entire DB for songs you don't have. You can also modify the timestamp to customize the range of this behavior.

The "real" download links are also cached in "cache.csv" to improve runtime and reduce bandwidth on subsequent runs.

Downloaded files are saved to the ./Cons/C3/ folder, relative to wherever you are running the script from.
If you have existing con files from C3, put them in this directory and the script will skip over them instead of re-downloading.

LINUX:

    INSTALL:

        - Requires perl. On Windows try Strawberry Perl (http://strawberryperl.com)
        - Install the following CPAN modules (preferably using cpanminus)
            - Mojo::UserAgent
            - Mojo::IOLoop
            - File::Basename

    BUILD:
        
        - Requires PAR::Packer from CPAN.
        - Either run build.sh or try it yourself:
            - pp -c -o c3downloader c3downloader.pl

    RUN:
    
        - perl c3downloader.pl



WINDOWS:

    INSTALL:
        
        - Install Strawberry Perl from http://strawberryperl.com
        - Install the following CPAN modules in a cmd prompt using the cpan command:
            - cpan Mojo::UserAgent
            - cpan Mojo::IOLoop
            - cpan File::Basename

    BUILD:

        - Requires you to install one more CPAN module
            - cpan PAR::Packer
        - Now either run build.bat or try it for yourself:
            - pp -c -o c3downloader.exe c3downloader.pl

    RUN:
       
        - Double click c3downloader.exe

