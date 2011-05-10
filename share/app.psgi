use Beagle;
use Beagle::Util;
use Beagle::Web;
use Beagle::Web::Router;

use Plack::Builder;
builder {
    enable 'Plack::Middleware::Static',
      path => sub { s!^/system/!! },
      root => catdir( Beagle::Web->share_root, 'public' );

    \&Beagle::Web::Router::handle_request;
}

