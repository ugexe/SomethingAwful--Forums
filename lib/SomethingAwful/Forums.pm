package SomethingAwful::Forums;
use strict;
use WWW::Mechanize;

sub login {
    my ($self, $mech, $username, $password) = @_;
    return unless($username ne '' && $password ne '');

    my $url = 'http://forums.somethingawful.com/account.php?action=loginform';
    $mech->get( URI->new($url) );

    $mech->submit_form(
        with_fields => {
            username => $username,
            password => $password,
        },
    );

    # check to see if login was a success
}


1;


__END__