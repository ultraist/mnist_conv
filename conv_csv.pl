use strict;
use warnings;
use MNIST;

#make_mnist_csv(
#  "mnist_train.cvs",
#  "train-images.idx3-ubyte",
#  "train-labels.idx1-ubyte");
make_mnist_csv(
  "mnist_test.cvs",
  "t10k-images.idx3-ubyte",
  "t10k-labels.idx1-ubyte");

sub make_mnist_csv
{
  my ($csv, $data_file, $label_file) = @_;
  my ($dataset, $rows, $cols) = MNIST::load_heaf($data_file, $label_file);
  open(CSV, '>', $csv) || die "$csv: $!\n";
  
  foreach my $label (keys(%$dataset)) {
    my $mat = $dataset->{$label};
    foreach my $vec (@$mat) {
      print CSV join(",", ($label, @$vec)), "\n";
    }
  }
  close(CSV);
}
