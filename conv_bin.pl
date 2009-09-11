use strict;
use warnings;
use MNIST;
use Storable qw(nstore);

make_mnist_bin(
  "mnist_train.bin",
  "train-images.idx3-ubyte",
  "train-labels.idx1-ubyte");
make_mnist_bin(
  "mnist_test.bin",
  "t10k-images.idx3-ubyte",
  "t10k-labels.idx1-ubyte");

sub make_mnist_bin
{
  my ($bin, $data_file, $label_file) = @_;
  my ($dataset, $rows, $cols) = MNIST::load_heaf($data_file, $label_file);
  nstore($dataset, $bin);
}

