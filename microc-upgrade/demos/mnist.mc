extern int load_mnist_data(
  fmatrix[] dst_fm_images,
  fmatrix[] dst_fm_labels,
  string image_filename,
  string label_filename
);

struct fc_model {
  fmatrix[] train_x;
  fmatrix[] train_y;
  fmatrix[] test_x;
  fmatrix[] test_y;
  fmatrix[] biases;
  fmatrix[] weights;
  int[] layer_sizes;
  int epochs;
  int mini_batch_size;
  float learning_rate;
  fp (float) weight_init;  /* how to initiailize param values */
  fp (float, float) activate;
  fp (float, float) activate_prime;
  fp (fmatrix, fmatrix, float) cost;
  fp (fmatrix, fmatrix, fmatrix) cost_prime;
}

struct backprop_deltas {
  fmatrix[] weight_deltas;
  fmatrix[] bias_deltas;
}

[struct backprop_deltas bpds] free() void {
  free_arr(bpds.weight_deltas);
  free_arr(bpds.bias_deltas);
  free(bpds);
}

[struct fc_model fc] free_model() void {
  free_arr(fc.train_x);
  free_arr(fc.train_y);
  free_arr(fc.test_x);
  free_arr(fc.test_y);
  free_arr(fc.biases);
  free_arr(fc.weights);
  return;
}

[struct fc_model fc] init_biases() void {
  int i;
  fc.biases = make(fmatrix, len(fc.layer_sizes) - 1);
  for (i = 1; i < len(fc.layer_sizes); i = i + 1) {
    fc.biases[i-1] = init_fmat_zero(fc.layer_sizes[i], 1);
    fc.biases[i-1] = populate_fmat(fc.biases[i-1], fc.weight_init);
  }
  return;
}

/* construct weight matrices and initialize with random values */
[struct fc_model fc] init_weights() void {
  int i;
  fc.weights = make(fmatrix, len(fc.layer_sizes) - 1);
  for (i = 1; i < len(fc.layer_sizes); i = i + 1) {
    fc.weights[i-1] = init_fmat_zero(fc.layer_sizes[i], fc.layer_sizes[i-1]);
    fc.weights[i-1] = populate_fmat(fc.weights[i-1], fc.weight_init);
  }
  return;
}

[struct fc_model fc] predict(fmatrix X) fmatrix {
  int i;
  fmatrix fm;
  for (i = 0; i < len(fc.weights); i = i + 1) {
    X = ((fc.weights[i] .. X) + fc.biases[i]) => f_fmat(fc.activate);
  }
  return X;
}

/* Zeros the update matrices for next minibatch */
[struct fc_model fc] zero_deltas(fmatrix[] weights, fmatrix[] biases) void {
  int i;
  for (i = 0; i < len(fc.weights); i = i + 1) {
    weights[i] = init_fmat_zero(
      rows(fc.weights[i]), cols(fc.weights[i])
    );
    biases[i] = init_fmat_zero(
      rows(fc.biases[i]), cols(fc.biases[i])
    );
  }
}

[struct fc_model fc] train() void {
  int: mini, e, i, train_idx, train_size, l;
  struct backprop_deltas bpds;
  fmatrix[]: sum_weight_deltas, sum_bias_deltas;
  int[] train_indices;

  /* initialize training indices */
  train_size = len(fc.train_x);
  train_indices = make(int, len(fc.train_x));
  for (i = 0; i < len(fc.train_x); i = i + 1) {
    train_indices[i] = i;
  }

  /* initialize parameters and update matrices */
  fc.init_weights();
  fc.init_biases();
  sum_weight_deltas = make(fmatrix, len(fc.weights));
  sum_bias_deltas = make(fmatrix, len(fc.biases));

  /* initialize delta matrices */
  bpds = make(struct backprop_deltas);
  bpds.weight_deltas = make(fmatrix, len(fc.weights));
  bpds.bias_deltas = make(fmatrix, len(fc.biases));

  for (e = 0; e < fc.epochs; e = e + 1) {
    printf("Epoch %d\n", e);
    fc.evaluate();
    train_idx = 0;
    shuffle(train_indices);

    while (train_idx < len(fc.train_x)) {
      // printf("data %d/%d\n", train_idx, train_size);
      fc.zero_deltas(sum_weight_deltas, sum_bias_deltas);
      /* accumulate over mini patch */
      for (
        mini = train_idx;
        mini < min_int(train_idx + fc.mini_batch_size, train_size);
        mini = mini + 1
      ) {
        i = train_indices[mini];
        fc.backprop(fc.train_x[i], fc.train_y[i], bpds);
        for (l = 0; l < len(sum_weight_deltas); l = l+1) {
          sum_weight_deltas[l] = sum_weight_deltas[l] + bpds.weight_deltas[l];
          sum_bias_deltas[l] = sum_bias_deltas[l] + bpds.bias_deltas[l];
        }
      }

      /* update network weights */
      for (l = 0; l < len(sum_weight_deltas); l = l + 1) {
        /* normalize */
        sum_weight_deltas[l] =
          sum_weight_deltas[l] * (fc.learning_rate / float_of_int(fc.mini_batch_size));
        sum_bias_deltas[l] =
          sum_bias_deltas[l] * (fc.learning_rate / float_of_int(fc.mini_batch_size));
        fc.weights[l] = fc.weights[l] - sum_weight_deltas[l];
        fc.biases[l] = fc.biases[l] - sum_bias_deltas[l];
      }
      train_idx = train_idx + fc.mini_batch_size;
    }
  }

  return;
}

[struct fc_model fc] evaluate() void {
  int: i, pred, correct, gold;
  fmatrix out;

  correct = 0;
  for (i = 0; i < len(fc.test_x); i = i + 1) {
    out = fc.predict(fc.test_x[i]);
    pred = argmax(out);
    gold = argmax(fc.test_y[i]);

    if (pred == gold) {
      correct = correct + 1;
    }
  }
  printf("test set accuracy: %d/%d = %f\n", correct, len(fc.test_x), float_of_int(correct) / float_of_int(len(fc.test_x)));
}

[struct fc_model fc] backprop(fmatrix x, fmatrix y, struct backprop_deltas bpds) void {
  int: i, num_param_layers;
  fmatrix: activation, z, z_prime, delta, actv_transpose;
  fmatrix[]: activations, zs;
  fp (float, float) activate_prime;
  fp (fmatrix, fmatrix, fmatrix) cost_prime;

  num_param_layers = len(fc.weights);

  activate_prime = fc.activate_prime;
  cost_prime = fc.cost_prime;

  activation = x;
  activations = make(fmatrix, len(fc.layer_sizes));
  activations[0] = x;
  zs = make(fmatrix, num_param_layers);

  /* zero out deltas */
  for (i = 0; i < len(fc.weights); i = i + 1) {
    bpds.weight_deltas[i] = init_fmat_zero(
      rows(fc.weights[i]), cols(fc.weights[i])
    );
    bpds.bias_deltas[i] = init_fmat_zero(
      rows(fc.biases[i]), cols(fc.biases[i])
    );
  }

  // forward pass
  for (i = 0; i < len(fc.weights); i = i + 1) {
    z = (fc.weights[i] .. activation) + fc.biases[i];
    zs[i] = z;
    activation = f_fmat(z, fc.activate);
    activations[i+1] = activation;
  }

  // TODO: cannot distinguish calling fp from method dispatch.
  // backward pass
  delta = cost_prime(activations[len(activations) - 1], y)
          * f_fmat(zs[len(zs)-1], activate_prime);
  bpds.bias_deltas[num_param_layers - 1] = delta;
  bpds.weight_deltas[num_param_layers - 1] =
    delta .. ((activations[len(activations) - 2])^);

  for (i = 2; i < len(fc.layer_sizes); i = i + 1) {
    z = zs[len(zs)-i];
    z_prime = f_fmat(z, activate_prime);
    delta = (((fc.weights[num_param_layers - i + 1])^) .. delta) * z_prime;
    bpds.bias_deltas[num_param_layers - i] = delta;
    // actv_transpose = ;
    bpds.weight_deltas[num_param_layers - i] = delta .. (activations[len(activations) - i - 1]^);
  }

  return;
}

float norm_init() {
  return rand_norm(0., 1.);
}

void free_dataset(fmatrix[] train_x, fmatrix[] train_y, fmatrix[] test_x, fmatrix[] test_y)
{
  free_arr(train_x);
  free_arr(train_y);
  free_arr(test_x);
  free_arr(test_y);
  return;
}

int main()
{
  int ret;
  struct fc_model fc;
  fmatrix[]: train_fm_images, train_fm_labels, test_fm_images, test_fm_labels;
  int[] layer_sizes;
  int: epochs, mini_batch_size;
  float learning_rate;
  fmatrix fm;

  srand(time());  // seed random generator

  /* define hyperparameters */
  epochs = 30;
  learning_rate = 3.0;
  mini_batch_size = 100;
  layer_sizes = (int[]) {784, 30, 10};

  fc = make(struct fc_model);

  train_fm_images = make(fmatrix, 50000);
  train_fm_labels = make(fmatrix, 50000);

  test_fm_images = make(fmatrix, 10000);
  test_fm_labels = make(fmatrix, 10000);

  /* Load train */
  ret = load_mnist_data(train_fm_images, train_fm_labels,
    "mnist_data/train-images-idx3-ubyte",
    "mnist_data/train-labels-idx1-ubyte"
  );
  if (ret != 0) {
    free_dataset(
      train_fm_images, train_fm_labels, test_fm_images, test_fm_labels
    );
    return -1;
  }

  /* Load test */
  ret = load_mnist_data(test_fm_images, test_fm_labels,
    "mnist_data/t10k-images-idx3-ubyte",
    "mnist_data/t10k-labels-idx1-ubyte"
  );
  if (ret != 0) {
    free_dataset(
      train_fm_images, train_fm_labels, test_fm_images, test_fm_labels
    );
    return -1;
  }

  /* Popuate fc model fields */
  fc.train_x = train_fm_images;
  fc.train_y = train_fm_labels;
  fc.test_x = test_fm_images;
  fc.test_y = test_fm_labels;
  fc.layer_sizes = layer_sizes;
  fc.epochs = epochs;
  fc.mini_batch_size = mini_batch_size;
  fc.learning_rate = learning_rate;
  fc.weight_init = norm_init;
  fc.activate = sigmoid;
  fc.activate_prime = sigmoid_prime;
  fc.cost = quadratic_cost;
  fc.cost_prime = quadratic_cost_prime;

  // print_mnist_image(fc.train_x[49999]);
  // print_mat(fc.train_y[49999]);
  // print_mnist_image(fc.test_x[9999]);
  // print_mat(fc.test_y[9999]);

  fc.train();

  // free_dataset(
  //   train_fm_images, train_fm_labels, test_fm_images, test_fm_labels
  // );
  return 0;
}