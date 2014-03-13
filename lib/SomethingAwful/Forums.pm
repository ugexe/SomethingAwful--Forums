package SomethingAwful::Forums;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use URI;
use LWP::Protocol::AnyEvent::http;
use WWW::Mechanize;
use Coro qw( async );
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
);

has 'logged_in' => (
    isa     => 'Int',
    is      => 'rw',
    default => 0,
);


method login(Str :$username!, Str :$password!) {
    $self->mech->get( URI->new_abs( 'account.php?action=loginform', $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            username => $username,
            password => $password,
        },
    );

    $self->logged_in(1);
    # check to see if login was a success
}


method reply_to_thread(Int :$thread_id!, Str :$body) {
    return if !$self->logged_in;
    $self->mech->get( URI->new_abs( "newreply.php?action=newreply&threadid=$thread_id", $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            message => $body,
        },
    );
}


method reply_to_post(Int :$post_id!, Str :$body) {
    return if !$self->logged_in;
    $self->mech->get( URI->new_abs( "newreply.php?action=newreply&postid=$post_id", $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            message => $body,
        },
    );
}


method fetch_forums {
    my $res = $self->mech->get( $self->base_url );
    return $self->index_scraper->scrape( $res->decoded_content, $self->base_url );
}


# Possibly allow Int|URI $forum, and if it is URI then use that instead of assuming the url
# see: Method-Signatures and MooseX::Method::Signatures 
method fetch_threads(Int :$forum_id!, Int|ArrayRef[Int] :$pages) {
    my @pages = ($pages);
    push @pages, ref $pages ? @$pages : $pages;

    my $sem = new Coro::Semaphore 1; # process 1 pages max at a time
    my @cs;
    my @unsorted_results;

    foreach my $page ( @pages ) {
        $sem->down;

        my $c = async {
            my $uri = URI->new_abs( "/forumdisplay.php?forumid=$forum_id&daysprune=15&perpage=40&posticon=0&sortorder=desc&sortfield=lastpost&pagenumber=$page", $self->base_url );
            my $res = $self->mech->get( $uri );

            warn "Forum fetch failed! forum_id: $forum_id page: $page" if !$self->mech->success;
            my $scraped = $self->forum_scraper->scrape( $res->decoded_content, $self->base_url );

            push( @unsorted_results, $scraped );
        };

        $sem->up;
        push(@cs, $c);
    }
    $_->join for (@cs);


    my @sorted_results = sort { $a->{page_info}->{current} <=> $b->{page_info}->{current} } @unsorted_results;
    return \@sorted_results;
}


method fetch_posts(Int :$thread_id!, Int|ArrayRef[Int] :$pages, Int :$per_page = 40) {
    my @pages = ($pages);
    push @pages, ref $pages ? @$pages : $pages;

    my $sem = new Coro::Semaphore 3; # Request 3 pages at a time max
    my @cs;
    my @unsorted_results;
    foreach my $page ( @pages ) {
        $sem->down;

        my $c = async {
            my $uri = URI->new_abs( "/showthread.php?threadid=$thread_id&pagenumber=$page&perpage=$per_page", $self->base_url );
            my $res = $self->mech->get( $uri );
            $sem->up; # release the lock now that we have the http::response to process

            warn "Thread fetch failed! thread_id: $thread_id page: $page" if !$self->mech->success;
            my $scraped = $self->thread_scraper->scrape( $res->decoded_content, $self->base_url );

            push( @unsorted_results, $scraped );
        };

        push(@cs, $c);
    }
    $_->join for (@cs);


    my @sorted_results = sort { $a->{page_info}->{current} <=> $b->{page_info}->{current} } @unsorted_results;
    return \@sorted_results;
}


__PACKAGE__->meta->make_immutable;
1;


__END__