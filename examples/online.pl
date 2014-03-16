use Modern::Perl;
use Getopt::Long::Descriptive;
use lib '../lib';
use SomethingAwful::Forums;

# List users/plats/mods/admins online for a specific forum

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',       { required => 0     }, ],
    [ 'password|p:s',   'hmmmmm',                     { required => 0     }, ],
    [ 'forum_id|f:i',   'forum_id to check',          { required => 1     }, ],
    [],
    [ 'help', 'print usage message and exit'                                 ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

say 'Starting...';

my $SA = SomethingAwful::Forums->new;
$SA->login(
    'username' => $opt->username,
    'password' => $opt->password,
) if ($opt->username && $opt->password);

my $scraped_users = $SA->fetch_online_users( forum_id => $opt->forum_id, );

foreach my $users_page ( @{ $scraped_users } ) {
    foreach my $type ( 'plats','users','admins','mods' ) {
        foreach my $user ( @{$users_page->{$type}} ) {
            say $type . ' | ' . $user->{username};
        }
    }
}


1;


__END__
