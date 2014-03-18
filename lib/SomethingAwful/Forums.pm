package SomethingAwful::Forums;
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use URI;
use LWP::Protocol::AnyEvent::http;
use WWW::Mechanize;
use Coro qw( async );
use HTTP::Cookies;
require SomethingAwful::Forums::Scraper::Index;
require SomethingAwful::Forums::Scraper::Forum;
require SomethingAwful::Forums::Scraper::Thread;
require SomethingAwful::Forums::Scraper::Users::Online;

=head1 NAME

SomethingAwful::Forums

=head1 SYNOPSIS

    use Modern::Perl;
    use SomethingAwful::Forums;
    use Data::Dumper;

    my $SA = SomethingAwful::Forums->new;

    $SA->login(
        'username' => 'something',
        'password' => 'awful',
    );

    my $scraped_thread = $SA->fetch_posts( 
        thread_id => 3343753, 
        pages     => 1, 
    );

    say Dumper( $scraped_thread ); 

    $SA->reply_to_thread( thread_id => 3343753, 'gas' );

=head1 DESCRIPTION

Scrape and post to the SomethingAwful.com forums.

See /examples folder.

=head1 OBJECTS


=head2 index_scraper

Web::Scraper::LibXML scraper for scraping forum's index page.

=cut

has 'index_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub { SomethingAwful::Forums::Scraper::Index->new; },
);


=head2 forum_scraper

Web::Scraper::LibXML scraper for scraping a specific forum.

=cut

has 'forum_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub{ SomethingAwful::Forums::Scraper::Forum->new; },
);


=head2 thread_scraper

Web::Scraper::LibXML scraper for scraping specific thread.

=cut

has 'thread_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub { SomethingAwful::Forums::Scraper::Thread->new; },
);


=head2 online_user_scraper

Web::Scraper::LibXML scraper for scraping current online users for a specific forum

=cut

has 'online_user_scraper' => ( 
    isa     => 'Web::Scraper::LibXML', 
    is      => 'ro',
    default => sub { SomethingAwful::Forums::Scraper::Users::Online->new; },
);



=head2 base_url

Contains the URL of the forum index. Allows use of an IP address if DNS fails to resolve.

=cut

has 'base_url' => ( 
    isa     => 'Str', 
    is      => 'rw', 
    default => 'http://forums.somethingawful.com/' 
);


=head2 mech

WWW::Mechanize object used internally to navigate web pages.

=cut
# TODO Make cookie file editable
has 'mech'     => ( 
    isa     => 'WWW::Mechanize', 
    is      => 'ro', 
    default => sub { 
        return WWW::Mechanize->new( 
            agent      => 'Mozilla/5.0 (Windows; U; Windows NT 6.1; nl; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13',
            autocheck  => 0,
            #cookie_jar => HTTP::Cookies->new(file => '.cookies', autosave => 1, ignore_discard => 1),
        );
    },
);


=head2 logged_in

Returns 1 if it successfully logged in. 

=cut

has 'logged_in' => (
    isa     => 'Int',
    is      => 'rw',
    default => 0,
);


=head1 METHODS

=head2 login ( username => $username, password => $password )

Login to forums using passed credentials. 

=cut


method login(Str :$username!, Str :$password!) {
    $self->mech->get( URI->new_abs( 'account.php?action=loginform', $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            username => $username,
            password => $password,
        },
    );

    $self->logged_in(1);
    $self->mech->cookie_jar->save;
    # check to see if login was a success
}


=head2 new_thread( forum_id => $forum_id, body => $body )

Post a new thread to a specific forum

=cut

method new_thread(Int :$forum_id!, Str :$body!, Str :$subject!, Int :$icon!) {
    return if !$self->logged_in;
    $self->mech->get( URI->new_abs( "newthread.php?action=newthread&forumid=$forum_id", $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            iconid  => $icon,
            subject => $subject,
            message => $body,
        },
    );
}



=head2 reply_to_thread ( thread_id => $thread_id, body => $body )

Reply to a specific thread

=cut

method reply_to_thread(Int :$thread_id!, Str :$body!) {
    return if !$self->logged_in;
    $self->mech->get( URI->new_abs( "newreply.php?action=newreply&threadid=$thread_id", $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            message => $body,
        },
    );
}


=head2 reply_to_post ( post_id => $post_id, body => $body )

Reply to a specific post.

=cut

method reply_to_post(Int :$post_id!, Str :$body!) {
    return if !$self->logged_in;
    $self->mech->get( URI->new_abs( "newreply.php?action=newreply&postid=$post_id", $self->base_url ) );

    $self->mech->submit_form(
        with_fields => {
            message => $body,
        },
    );
}


=head2 fetch_forums

Return a hashref representing the scraped forum index.

=cut

method fetch_forums {
    my $res = $self->mech->get( $self->base_url );
    return $self->index_scraper->scrape( $res->decoded_content, $self->base_url );
}


=head2 fetch_threads ( forum_id => $forum_id, pages => [1,2] )

Return a hashref repsenting the threads scraped from the supplied pages of the supplied forum id.

=cut

# Possibly allow Int|URI $forum, and if it is URI then use that instead of assuming the url
# see: Method-Signatures and MooseX::Method::Signatures 
method fetch_threads(Int :$forum_id!, Int|ArrayRef[Int] :$pages = 1) {
    my @page_list;
    push @page_list, ref $pages ? @$pages : $pages;

    my @results;
    foreach my $page ( @page_list ) {
        my $uri   = URI->new_abs( "/forumdisplay.php?forumid=$forum_id&daysprune=15&perpage=40&posticon=0&sortorder=desc&sortfield=lastpost&pagenumber=$page", $self->base_url );
        my $res   = $self->mech->get( $uri );

        warn "Forum fetch failed! forum_id: $forum_id page: $page" if !$res->is_success;
        my $scraped = $self->forum_scraper->scrape( $res->decoded_content, $self->base_url );

        push( @results, $scraped );
    }


    return \@results;
}


=head2 fetch_posts ( thread_id => $thread_id, pages => [1,2] )

Return a hashref repsenting the posts scraped from the supplied pages of the supplied thread id.

=cut

method fetch_posts(Int :$thread_id!, Int|ArrayRef[Int] :$pages = 1, Int :$per_page = 40, Int :$threads = 3) {
    my @page_list;
    push @page_list, ref $pages ? @$pages : $pages;

    my $sem = Coro::Semaphore->new($threads); # Process $threads pages at a time max
    my @cs;
    my @unsorted_results;
    foreach my $page ( @page_list ) {
        $sem->down;

        my $c = async {
            my $guard = $sem->guard;
            my $uri   = URI->new_abs( "/showthread.php?threadid=$thread_id&pagenumber=$page&perpage=$per_page", $self->base_url );
            my $res   = $self->mech->get( $uri );

            if( !$res->is_success ) {
                warn "Thread fetch failed! thread_id: $thread_id page: $page";                
                return;
            }
            else {
                my $scraped = $self->thread_scraper->scrape( $res->decoded_content, $self->base_url );
                push( @unsorted_results, $scraped );
            }
        };

        push(@cs, $c);
    }
    $_->join for (@cs);


    my @sorted_results = sort { $a->{page_info}->{current} <=> $b->{page_info}->{current} } @unsorted_results;
    return \@sorted_results;
}


=head2 fetch_online_users ( forum_id => $forum_id, pages => 0 )

Return a hashref repsenting the online users for a specific forum. pages => 0 for all pages

=cut

method fetch_online_users(Int :$forum_id!, Int|ArrayRef[Int] :$pages = 0 ) {
    my @page_list;
    push @page_list, ref $pages ? @$pages : ($pages?$pages:1);

    my @results;

    while( my $page = shift @page_list ) {
        my $uri   = URI->new_abs( "/online.php?forumid=$forum_id&pagenumber=$page", $self->base_url );
        my $res   = $self->mech->get( $uri );

        if( !$res->is_success ) {
            warn "Online user fetch failed! forum_id: $forum_id page: $page";                
            return;
        }
        else {
            my $scraped = $self->online_user_scraper->scrape( $res->decoded_content, $self->base_url );

            # handle request for page = 0 aka all pages
            if($page == 1 && $pages == 0) {
                foreach my $page_num (2..$scraped->{page_info}->{last}) {
                    push @page_list, $page_num;
                }
            }

            push( @results, $scraped );
        }
    }

    return \@results;
}


=head1 AUTHOR

ugexe

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;


__END__