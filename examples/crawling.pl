use v5.10;
use strict;
use warnings;
use WWW::Mechanize;
use URI;
use Getopt::Long::Descriptive;
use lib '../lib';
require SomethingAwful::Forums::Scraper::Index;
require SomethingAwful::Forums::Scraper::Forum;
require SomethingAwful::Forums::Scraper::Thread;
require SomethingAwful::Forums;

# Example of how to scrape the forum's index, navigate to and scrape the first forum, then navigate
# to and scrape the first thread while finally outputting the first post of this thread.
# Remember login credentials are often required to view many forums/threads, but not always.

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?', ],
    [ 'password|p:s',   'hmmmmm',               ],
    [],
    [ 'help', 'print usage message and exit'    ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $FORUMS_INDEX_URL = 'http://forums.somethingawful.com';

# Should switch to async safe LWP module in the future
my $mech = WWW::Mechanize->new(
    agent     => 'Mozilla/5.0 (Windows; U; Windows NT 6.1; nl; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13',
    autocheck => 1,
);

my $index_scraper  = SomethingAwful::Forums::Scraper::Index->new;
my $forum_scraper  = SomethingAwful::Forums::Scraper::Forum->new;
my $thread_scraper = SomethingAwful::Forums::Scraper::Thread->new;

###########################################################################################

say 'Starting...';
if($opt->username ne '' && $opt->password ne '') {
    SomethingAwful::Forums->login($mech, $opt->username, $opt->password);
}
else {
    say 'No login credentials supplied. Not logging in.'
}

$mech->get( URI->new('http://forums.somethingawful.com/') );
my $scraped_index = $index_scraper->scrape( $mech->content, $mech->base );

if( exists $scraped_index->{logged_in_as_username} ) {
    say "Logged in as: " . $scraped_index->{logged_in_as_username} if exists $scraped_index->{logged_in_as_username};

    if( exists $scraped_index->{pm_info} ) {
        say "Messages: ";
        say "\ttotal["  . $scraped_index->{pm_info}->{total}  . "]" if $scraped_index->{pm_info}->{total};
        say "\tunread[" . $scraped_index->{pm_info}->{unread} . "]" if $scraped_index->{pm_info}->{unread};
        say "\tnew["    . $scraped_index->{pm_info}->{new}    . "]" if $scraped_index->{pm_info}->{new}; 
    }
}


# Do some processing on the data (gather forum data & process the first forums first page of threads)
foreach my $forum ( @{$scraped_index->{forums}} ) {
    $mech->get( $forum->{url} ) ;
    my $scraped_forum = $forum_scraper->scrape( $mech->content, $mech->base );

    say 'Found data for: ' . scalar @{$scraped_forum->{threads}} . ' threads';

    foreach my $thread ( @{$scraped_forum->{threads}} ) {
        next unless $thread->{counts}->{reply} > 200; # Check reply counts!
        next if $thread->{counts}->{page}      > 10;  # and page counts! wow!
        say "Scraping thread: " . $thread->{title};

        foreach my $page_number ( 1 .. $thread->{counts}->{page} ) {
            my $page_url = $thread->{url}->as_string;
            $page_url    =~ s{pagenumber=(\d+)}{$page_number};
            say 'Getting page: ' . $page_number;

            $mech->get( URI->new( $page_url) );
            my $scraped_thread_page = $thread_scraper->scrape( $mech->content, $mech->base );

            foreach my $post ( @{$scraped_thread_page->{posts}} ) {
                say $post->{post};
                # do something with each post
                last;
            }

            last;
        }

        last; # lets only do this once for the example
    }

    last;
}


1;


__END__
