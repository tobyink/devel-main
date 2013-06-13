# ABSTRACT: Syntactic sugar for a script's main routine
use strict;
use warnings;

package Devel::Main {

    # We use Sub::Exporter so you can import main with different names
    # with 'use Devel::Main 'main' => { -as => 'other' }
    use Sub::Exporter 0.985;
    Sub::Exporter::setup_exporter(
        {
            exports => {
                'main' => \&main_generator
            }
        }
    );

    # Later versions will let you customize this
    our $Main_Sub_Name = 'run_main';

    sub main_generator {
        my ( $class, $name, $args ) = @_;

        my $run_sub_name = $args->{'run_sub_name'} // "run_$name";
        my $exit         = $args->{'exit'}         // 1;

        return sub (&) {
            my ($main_sub) = @_;

            # If we're called from a script, run main and exit
            if ( !defined caller(1) ) {
                $main_sub->();
                exit(0) if $exit;
            }

            # Otherwise, create a sub that turns its arguments into @ARGV
            else {
                no strict 'refs';
                my $package = caller;
                *{"${package}::$run_sub_name"} = sub {
                    local @ARGV = @_;
                    return $main_sub->();
                };

                # Return 1 to make the script pass 'require'
                return 1;
            }
        };
    }

};

1;

__END__

=head1 SYNOPSIS

  use Devel::Main 'main';
  
  main {
    # Your main routine goes here
  };

=head1 DESCRIPTION

This module provides a clean way of specifying your script's main routine.

=method main()

Declares your script's main routine.

=head1 CREDITS

This module was inspired by Brian D. Foy's article "Five Ways to Improve Your Perl Programming" (http://www.onlamp.com/2007/04/12/five-ways-to-improve-your-perl-programming.html).

=cut
