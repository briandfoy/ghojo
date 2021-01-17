use v5.26;

package Ghojo::Constants;
use Exporter qw(import);

use constant LOGIN_FAILURE             =>  1;
use constant REQUIRES_TWO_FACTOR       =>  2;
use constant REQUIRES_AUTHENTICATION   =>  3;
use constant BAD_CREDENTIALS           =>  4;
use constant TOO_MANY_LOGIN_ATTEMPTS   =>  5;
use constant COULD_NOT_READ_TOKEN_FILE =>  6;
use constant NO_OWNER_REPO_PAIR        =>  7;
use constant PROFILE_ERROR             =>  8;
use constant PROFILE_INPUT_ERROR       =>  9;
use constant PROFILE_VALIDATION_ERROR  => 10;
use constant UNKNOWN_HTTP_VERB         => 11;
use constant ARGS_MUST_BE_HASH_REF     => 12;
use constant MODULE_LOAD_FAILURE       => 13;
use constant BAD_PACKAGE_NAME          => 14;

use constant RESOURCE_NOT_FOUND        => 404;

our @EXPORT = qw(
	LOGIN_FAILURE
	REQUIRES_TWO_FACTOR
	REQUIRES_AUTHENTICATION
	BAD_CREDENTIALS
	TOO_MANY_LOGIN_ATTEMPTS
	COULD_NOT_READ_TOKEN_FILE
	NO_OWNER_REPO_PAIR
	PROFILE_ERROR
	PROFILE_INPUT_ERROR
	PROFILE_VALIDATION_ERROR
	UNKNOWN_HTTP_VERB
	ARGS_MUST_BE_HASH_REF
	MODULE_LOAD_FAILURE
	RESOURCE_NOT_FOUND
	BAD_PACKAGE_NAME
	);

1;
