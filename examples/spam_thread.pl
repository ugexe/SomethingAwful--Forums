use Modern::Perl;
use Getopt::Long::Descriptive;
use Try::Tiny;
use lib '../lib';
use SomethingAwful::Forums;

# Spam a specific thread with the same message multiple times

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',           { required => 1 }, ],
    [ 'password|p:s',   'hmmmmm',                         { required => 1 }, ],
    [ 'thread_id|t:i',  'thread_id to use',               { required => 1 }, ],
    [ 'message|m:s',    'message to post to each thread', { required => 1 }, ],
    [ 'goatse',         'add goatse to your posts',                          ],    
    [ 'max',            'max replies (0 = unlimited)',    { default  => 0 }, ],    
    [ 'sleep|s:i',      'Seconds to sleep between posts', { default  => 3 }, ],
    [],
    [ 'help', 'print usage message and exit'                                 ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $message = $opt->message;
if( $opt->goatse ) {
    $message .= qw([img]http://www.goatse.info/hello.jpg[/img]);    
}

my $SA = SomethingAwful::Forums->new;

say 'Starting...';

$SA->login(
    'username' => $opt->username,
    'password' => $opt->password,
);

while(1) {
    try {
        $SA->reply_to_thread( 
            thread_id => $opt->thread_id, 
            body      => ( $message . ( ' [b][/b]' x int(rand(1000)) ) ), # add nonsense to bypass duplicate detection
        );

        state $counter++;
        last if( $opt->max > 0 && $counter >= $opt->max);
    };

    sleep($opt->sleep);
}


1;


__END__
