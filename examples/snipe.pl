use Modern::Perl;
use Getopt::Long::Descriptive;
use lib '../lib';
use Number::Range;
use SomethingAwful::Forums;

# Snipe somethingawful threads.

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',       { required => 1     }, ],
    [ 'password|p:s',   'hmmmmm',                     { required => 1     }, ],
    [ 'forum_id|f:i',   'thread_id to use',           { required => 1     }, ],
    [ 'pages|pg:s',     'pages of forum to use',      { default  => '1,2' }, ],
    [ 'max|m:i',        'Max snipes (0 = no limit)',  { default  => 5     }, ],
    [ 'limited',        'Only snipe pages 2,3,and 69',                       ],
    [],
    [ 'help', 'print usage message and exit'                                 ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my @pages = Number::Range->new($opt->pages)->range;

say 'Starting...';

my $SA = SomethingAwful::Forums->new;
$SA->login(
    'username' => $opt->username,
    'password' => $opt->password,
);
my $scraped_forum = $SA->fetch_threads( forum_id => $opt->forum_id, pages => \@pages );

# Allows breaking out of 2 loops while declaring state $counter on an inner loop
CRAWLER: {
    foreach my $forum_page ( @{ $scraped_forum } ) {
        foreach my $thread ( @{ $forum_page->{threads} } ) {
            next if ($thread->{counts}->{reply} + 1) % 40;

            my $snipe = ':sicknasty:';
            my $next_page = ($thread->{counts}->{page} + 1);

            if( $next_page == 2 ) {
                $snipe = ':synpa:';
            }
            elsif( $next_page == 3 ) {
                $snipe = ':page3:';
            }
            elsif( $next_page == 69 ) {
                $snipe = ':69snypa:';
            }
            else {
                next if $opt->limited;
            }

            $SA->reply_to_thread( thread_id => $thread->{id}, body => $snipe );
            say 'Sniped: ' . $snipe . ' | ' . $thread->{title};
            state $counter++;
            last CRAWLER if( $counter != 0 && $counter >= $opt->max );
        }
    }
}


1;


__END__
