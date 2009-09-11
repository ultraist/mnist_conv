use strict;
use warnings;
use MNIST;
use Imager;

$| = 1;

make_mnist_image(
  "mnist_train",
  "train-images.idx3-ubyte",
  "train-labels.idx1-ubyte");
make_mnist_image(
  "mnist_test",
  "t10k-images.idx3-ubyte",
  "t10k-labels.idx1-ubyte");

sub make_mnist_image
{
  print "loading ..\r";
  
  my ($prefix, $data_file, $label_file) = @_;
  my ($dataset, $rows, $cols) = MNIST::load_half($data_file, $label_file);
  
  foreach my $label (keys(%$dataset)) {
    my @digit_imgs = ();
    my $c = 0;
    my $mat = $dataset->{$label};
    
    foreach my $vec (@$mat) {
      print "$prefix draw $label .. $c\r";
      my $img = Imager->new(ysize => $rows, xsize =>$cols);
      for (my $i = 0; $i < scalar(@$vec); ++$i) {
        my $x = $i % $cols;
        my $y = int($i / $cols);
        my $gray = $vec->[$i];
        $img->setpixel(x => $x,
                       y => $y,
                       color => Imager::Color->new(
                         r => $gray, g => $gray, b => $gray
                       )
        );
      }
      push(@digit_imgs, $img);
      ++$c;
    }
    
    my $list_cols = get_cols(scalar(@digit_imgs));
    my $digit_list_img =  Imager->new(
      ysize => $rows * (int(scalar(@digit_imgs) / $list_cols)
                        + (scalar(@digit_imgs) % $list_cols == 0 ? 0:1)),
      xsize => $list_cols * $cols
    );
    
    for (my $i = 0; $i < scalar(@digit_imgs); ++$i) {
      my $x = $i % $list_cols;
      my $y = int($i / $list_cols);
      $digit_list_img->paste(
        left => $x * $cols,
        top => $y * $rows,
        img => $digit_imgs[$i]
      );
    }
    $digit_list_img->write(file => "${prefix}${label}.bmp", type => 'bmp');
    
    print "\n";
  }
}

sub get_cols
{
  my $n = shift;
  return 30;
}
 