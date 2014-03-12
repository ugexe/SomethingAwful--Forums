package SomethingAwful::Forums;
use Moose;
use namespace::autoclean;
use URI;
use WWW::Mechanize;
require SomethingAwful::Forums::Scraper::Index;
require SomethingAwful::Forums::Scraper::Forum;
require SomethingAwful::Forums::Scraper::Thread;

has 'index_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub { SomethingAwful::Forums::Scraper::Index->new; },
);

has 'forum_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub{ SomethingAwful::Forums::Scraper::Forum->new; },
);

has 'thread_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub { SomethingAwful::Forums::Scraper::Thread->new; },
);

has 'base_url' => ( 
    isa     => 'Str', 
    is      => 'rw', 
    default => 'http://forums.somethingawful.com/' 
);

has 'mech'     => ( 
    isa     => 'WWW::Mechanize', 
    is      => 'ro', 
    default => sub { 
        return WWW::Mechanize->new( 
            agent     => 'Mozilla/5.0 (Windows; U; Windows NT 6.1; nl; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13',
            autocheck => 1,
        );
    },
    handles => [qw( get content )],
);

has 'username' => ( 
    isa => 'Str', 
    is  => 'rw', 
);

has 'password' => ( 
    isa => 'Str', 
    is  => 'rw' 
);


sub login {
    my $self = shift;
    return unless($self->username ne '' && $self->password ne '');

    $self->mech->get( URI->new_abs( 'account.php?action=loginform', $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            username => $self->username,
            password => $self->password,
        },
    );

    # check to see if login was a success
}


sub fetch_forums {
    my $self = shift;

    $self->get( $self->base_url );
    return $self->index_scraper->scrape( $self->mech->content, $self->mech->base );
}


__PACKAGE__->meta->make_immutable;
1;


__END__