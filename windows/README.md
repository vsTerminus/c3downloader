build.bat: Use this to build a Windows executable from the Perl source.

Note: Requires you to install a few things:

1. Strawberry Perl (from http://strawberryperl.com) so you can run perl on Windows

Install the rest from cpan by opening a windows cmd prompt and typing:

2. cpan PAR::Packer
4. cpan Mojo::UserAgent
6. cpan Mojo::IOLoop
5. cpan JSON::Parse
6. cpan File::Basename

Now just run build.bat to compile the Perl script into an executable that can be run on Windows with or without Perl installed.

c3downloader.bat: 

    Once you've built an executable use this bat file to run it. The bat file will take care of creating the cons/c3 directory for you.
