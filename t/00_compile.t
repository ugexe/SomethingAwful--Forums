use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok 'SomethingAwful::Forums' }

BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Index'         }
BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Forum'         }
BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Thread'        }

BEGIN { use_ok 'SomethingAwful::Forums::Scraper::Users::Online' }

1;