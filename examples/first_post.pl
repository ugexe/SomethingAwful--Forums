use Modern::Perl;
use Getopt::Long::Descriptive;
use Number::Range;
use Acme::Goatse;
use lib '../lib';
use SomethingAwful::Forums;

# Snipe somethingawful threads.

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',       { required => 1     }, ],
    [ 'password|p:s',   'hmmmmm',                     { required => 1     }, ],
    [ 'forum_id|f:i',   'forum_id to use',            { required => 1     }, ],
    [ 'recheck_after:i','Rerun every X seconds',                             ],
    [ 'message|m:s',    'message to post to each thread', { required => 1 }, ],
    [ 'goatse',         'add acsii goatse to your posts',                    ],    
    [],
    [ 'help', 'print usage message and exit'                                 ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $message = $opt->message;
if( $opt->goatse ) {
    $message .= '[code]' . goatse() . '[/code]';    
}

say 'Starting...';

my $SA = SomethingAwful::Forums->new;
$SA->login(
    'username' => $opt->username,
    'password' => $opt->password,
);


while(1) {
    my $waketime = ($opt->recheck_after?( time + $opt->recheck_after ):0);
    my $scraped_forum = $SA->fetch_threads( forum_id => $opt->forum_id, pages => \@pages );

    foreach my $forum_page ( @{ $scraped_forum } ) {
        foreach my $thread ( @{ $forum_page->{threads} } ) {
            next if $thread->{counts}->{reply};

            $SA->reply_to_thread( thread_id => $thread->{id}, body => $message );
        }
    }

    if( $waketime ) {
        my $sleep_for = $waketime - time;
        $sleep_for = $opt->recheck_after if $sleep_for <= 0;
        say "Rechecking in $sleep_for seconds";
        sleep( $sleep_for );
    }
    else {
        last;
    }
}


1;


__END__
