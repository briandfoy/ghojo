use v5.26;

package Ghojo::Data;
use experimental qw(signatures);
use parent qw( Hash::AsObject ); # as a quick fix. I'd rather lose the dependency

use Ghojo::Mixins::SuccessError;


# until we need to build out these classes
my @classes = qw(
	SSHKey GPGKey UserRecord Email Grant Repo
	Emojis License Gitignore Content RawContent LicenseContent
	Issue Reaction Label HTMLContent Secret
	);

foreach my $class ( @classes ) {
	no strict 'refs';
	@{ "Ghojo::Data::$class\::ISA" } = __PACKAGE__;
	}

package Ghojo::Data::LicenseContent {
	use Mojo::Util qw(b64_decode);

	sub raw_content ( $self ) {
		return $self->{raw_content} if exists $self->{raw_content};
		$self->{raw_content} = b64_decode( $self->{content} )
		}
	}

package Ghojo::Data::Content {
	sub new ( $class, $content ) {
		$class->entered_sub;
		$class->logger->debug( "Creating $class with\n$content" );
		bless { content => $content }, $class;
		}

	sub logger ( $self ) { Ghojo->logger }

	sub content ( $self ) { $self->{content} }
	sub type ( $self ) {
		my $class = ref $self;
		$class =~ s/.*:://;
		lc $class;
		}

	sub is_raw       ( $self ) { 0 }
	sub is_html      ( $self ) { 0 }
	sub is_base64    ( $self ) { 0 }
	sub is_file      ( $self ) { 0 }
	sub is_directory ( $self ) { 0 }
	sub is_symlink   ( $self ) { 0 }
	sub is_submodule ( $self ) { 0 }
	sub is_unknown   ( $self ) { 1 }
	sub is_known     ( $self ) { ! $self->is_unknown }
	sub is_secret    ( $self ) { 0 }

	sub DESTROY ( $self ) { 1 }
	}

package Ghojo::Data::Content::KnownType {
	our @ISA = qw(Ghojo::Data::Content);
	sub is_unknown ( $self ) { 0 }
	}

package Ghojo::Data::Content::Raw {
	our @ISA = qw(Ghojo::Data::Content::KnownType);

	sub new ( $class, $content ) {
		$class->SUPER::new( $content );
		}

	sub is_raw ( $self ) { 1 }
	}

package Ghojo::Data::Content::HTML {
	our @ISA = qw(Ghojo::Data::Content::KnownType);

	sub new ( $class, $content ) {
		$class->SUPER::new( $content );
		}

	sub is_html ( $self ) { 1 }
	}

=pod


	state $types_to_classes = {
		'file'      => 'Ghojo::Data::Content::File',
		'symlink'   => 'Ghojo::Data::Content::Symlink',
		'submodule' => 'Ghojo::Data::Content::Submodule',
		'dir'       => 'Ghojo::Data::Content::Directory',
		'default'   => 'Ghojo::Data::Content::Unknown',
		};

=cut

package Ghojo::Data::Content::Symlink {
	our @ISA = qw(Ghojo::Data::Content::KnownType);
	sub is_symlink ( $self ) { 1 }
	}

package Ghojo::Data::Content::Submodule {
	our @ISA = qw(Ghojo::Data::Content::KnownType);
	sub is_submodule ( $self ) { 1 }
	}

package Ghojo::Data::Content::Directory {
	our @ISA = qw(Ghojo::Data::Content::KnownType);
	sub is_directory ( $self ) { 1 }
	}

package Ghojo::Data::Content::DirectoryListing {
	our @ISA = qw(Ghojo::Data::Content::KnownType);
	sub is_diretory_listing ( $self ) { 1 }
	sub files ( $self ) { $self->@* }
	}

package Ghojo::Data::Secret {
	our @ISA = qw(Ghojo::Data::Content::KnownType);
	sub is_secret ( $self ) { 1 }
	}

package Ghojo::Data::Workflow {
	our @ISA = qw(Ghojo::Data::Content::KnownType);
	sub files ( $self ) { $self->@* }
	}

package Ghojo::Data::String {
	sub is_secret ( $self ) { 1 }
	sub new ( $class, $string ) {
		say STDERR __PACKAGE__ . " with <$string>";
		bless \$string, $class;
		}

	sub string ( $self ) { $$self }
	}

=encoding utf8

=head1 NAME

Ghojo::Data - Create classes and inheritance for the JSON responses

=head1 SYNOPSIS

	use Ghojo::Data;

=head1 DESCRIPTION

This module is here until we come up with a better way to play with the
responses from the API. Now it's just all L<Hash::AsObject>.

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2024, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
