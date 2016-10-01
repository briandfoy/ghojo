use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Repo 0.001001 {
	use Carp qw(carp);

	sub new_from_response ( $class, $ghojo, $response ) {
		my( $owner, $repo ) = split m{/}, $response->{full_name};
		bless {
			ghojo => $ghojo,
			owner => $owner,
			repo  => $repo,
			data  => $response
			}, $class;
		}

	sub ghojo ( $self ) { $self->{ghojo} }
	sub owner ( $self ) { $self->{owner} }
	sub repo  ( $self ) { $self->{repo}  }
	sub data  ( $self ) { $self->{data}  }

	sub AUTOLOAD ( $self, @args ) {
		our $AUTOLOAD;
		my $method = $AUTOLOAD =~ s/.*:://r;
		unless( $self->ghojo->can( $method ) ) {
			carp "Cannot locate method $method";
			}

		$self->ghojo->logger->trace(
			sprintf "Calling $method with <%s %s> <@args>",
				$self->owner,
				$self->repo
			 );
		$self->ghojo->$method( $self->owner, $self->repo, @args );
		}

	sub DESTROY { }
	}

1;
