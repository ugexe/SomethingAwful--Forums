package SomethingAwful::Forums::Scraper::Forum;
use strict;
use Web::Scraper;
require HTML::TreeBuilder::LibXML; # only needed for Web::Scraper::LibXML
use Regexp::Common;

our $VERSION = '0.01';

sub new {
    return scraper {
        process '//table[@id="subforums"]//tr[@class="subforum"]', 
            'subforums[]' => scraper {
                process '//td[@class="title"]/a', 
                    title => 'TEXT', 
                    uri   => '@href', 
                    id    => sub {
                        return ($_[0]->attr('href') =~ s{^.*forumid=(\d+).*?$}{$1}ir);
                    };
                process '//td[@class="topics"]', 
                    topic_count => 'TEXT';
                process '//td[@class="posts"]', 
                    post_count => 'TEXT';            
            };
        process '//div[@class="pages top"]', 
            page_info => scraper {
                process '//select//option[last()]', 
                    last    => 'TEXT';
                process '//select//option[@selected]', 
                    current => 'TEXT';
            };        
        process '//tr[@class="thread"]', 
            'threads[]' => scraper {
                process '//td[@class="star"]', 
                    star      => 'TEXT';
                process '//td[@class="icon"]/img', 
                    url       => '@src', 
                    post_icon  => sub {
                        return $_[0]->attr('src') =~ s{.*#(\d+)$}{$1}r;
                    };
                process '//td[contains(@class, "title_sticky")]', 
                    sticky    => sub { return 1; };
                process '//div[@class="lastseen"]//a[@class="count"]', 
                    unread    => 'TEXT';
                process '//div[@class="info"]//a[@class="thread_title"]', 
                    title     => 'TEXT', 
                    uri       => '@href', 
                    id        => sub {
                        return ( $_[0]->attr('href') =~ s{^.*?threadid=(\d+).*?$}{$1}ir );
                    };
                process '//td[@class="author"]', 
                    author    => 'TEXT';
                process '//td[@class="author"]/a', 
                    author_id => sub {
                        return ( $_[0]->attr('href') =~ s{^.*?userid=(\d+).*?$}{$1}ir );
                    };
                process '//td[@class="replies"]', 
                    counts    => sub {
                        return {
                            reply => $_[0]->as_text,
                            page  => int( ($_[0]->as_text + 1) / 40 ),
                        };
                    };
                process '//td[@class="views"]', 
                    views     => 'TEXT';
                process '//td[@class="rating"]/img', 
                    rating    => sub {
                        return { 
                            stars   => ( $_[0]->attr('src')   =~ s{^.*?(\d+)stars.*?$}{$1}ir ),
                            average => ( $_[0]->attr('title') =~ s{^.*?($RE{num}{real}) average.*?$}{$1}ir ),
                            votes   => ( $_[0]->attr('title') =~ s{^.*?(\d+) votes.*?$}{$1}ir ),
                        };                 
                    };
                process '//td[@class="lastpost"]', 
                    last_post  => scraper {
                        process '//div[@class="date"]', 
                            date   => 'TEXT';
                        process '//a[@class="author"]', 
                            author => 'TEXT', 
                            uri    => '@href';
                    };

            };
    };        
}


1;


__END__
