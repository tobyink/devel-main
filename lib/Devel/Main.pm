# ABSTRACT: Syntactic sugar for a script's main routine
use strict;
use warnings;

package Devel::Main;

our $VERSION = 0.003;

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

1;

__END__

=head1 SYNOPSIS

  use Devel::Main 'main';
  
  main {
    # Your main routine goes here
  };

=head1 DESCRIPTION

This module provides a clean way of specifying your script's main routine.

=head1 METHODS

=method main()

Declares your script's main routine. Exits when done.

If, instead of executing your script, you load it with C<use> or C<require>, C<main> creates a subroutine named C<run_main> in the current package. You can then call this subroutine to run your main routine. Arguments passed to this subroutine will override C<@ARGV>.

Example:

  require './my_script.pl';
  
  run_main( 'foo' );  # Calls the main routine with @ARGV = ('foo')

If you alias the 'main' routine to another name, the "run" method will also be aliased. For example, if 'my_script.pl' had said:

  use Devel::Main main => { -as => 'primary' };
  
  primary {
    # Main code here
  };

then the installed subroutine would be called 'run_primary'.

You can also control whether or not the script exits after the main routine via the import parameter 'exit'.

   use Devel::Main 'main' => { 'exit' => 0 };
   
   main {
     # Main routine
   };
   print "Still running\n";

Finally, you can change the name of the subroutine to call the main routine via the import parameter 'run_sub_name'.

   # In 'my_script.pl'
   use Devel::Main 'main' => { 'run_sub_name' => 'run_the_main_routine' };
   
   # In other (test?) script
   require './my_script.pl';
   
   run_the_main_routine('bar'); # Calls the main routine with @ARGV = ('bar');

=head1 CREDITS

This module was inspired by Brian D. Foy's article "Five Ways to Improve Your Perl Programming" (http://www.onlamp.com/2007/04/12/five-ways-to-improve-your-perl-programming.html).

=cut
