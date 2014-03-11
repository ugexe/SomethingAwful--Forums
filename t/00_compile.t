use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok 'SomethingAwful::Forums' }

BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Index' }
BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Forum' }
BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Thread' }


1;