This is an artifact for accepted paper 163 of Euro-Par 2020,
"Improving mapping for sparse direct solvers: A trade-off between data
locality and load balancing" by authors Changjiang Gou, Ali Al Zoobi,
Anne Benoit, Mathieu Faverge, Loris Marchal, Grégoire Pichon, and
Pierre Ramet.

## Contents
* overview, which introduces the basic softwares and details steps on how to reproduce experiments.
* raw_results, which includes all raw results and the R script to clean the results and to plot curves.
* scripts, which contains all bash scripts used to generate raw datas and to download matrices.

* pastix_sharedM, an empty directory, where PaStiX is supposed to be installed.
* pastix_distributed, an empty directory, where PaStiX is supposed to be installed, with MPI option on.
* matrice, where the matrices used in our experiments should be placed. 

More informations can be found in file overview to reproduce the results.

## Getting started

* Install dependencies
```sh
sudo apt-get install git cmake g++ gfortran \
	                 libhwloc-dev libscotch-dev \
					 libopenblas-dev liblapacke-dev \
				     python-numpy openmpi-bin
```

* Setup the variable for the location of the artifact directory, and
let's consider everything will be done from that directory if not
specified.
```sh
export ARTIFACTS_DIR=path_to_the_artifact_directory
cd $ARTIFACTS_DIR
```

* Clone the repository and backup the directory for future uses
```sh
git clone -b europar2020 --recursive https://gitlab.inria.fr/solverstack/pastix.git
```

* Let's create the shared memory build and test it
```sh
cd $ARTIFACTS_DIR/pastix_sharedM
cmake $ARTIFACTS_DIR/pastix -DPASTIX_WITH_MPI=OFF -DPASTIX_INT64=OFF
make -j 8
./example/simple -9 20:20:20 
```

* Let's create the distributed memory build and test it
```sh
cd $ARTIFACTS_DIR/pastix_distributed
cmake $ARTIFACTS_DIR/pastix -DPASTIX_WITH_MPI=ON -DPASTIX_INT64=OFF
make -j 8
mpirun -np 2 ./example/simple -9 20:20:20 
```

## Reproduce results

* Download the matrices used. This may take some time and a lot of memory.
```sh
cd $ARTIFACTS_DIR/scripts
./download_matrices.sh
```

* Analysis results on a shared memory context on an example matrix
```sh
./pastix_sharedM/example/analyze -3 ./matrice/1138_bus.mtx -v4 -i iparm_allcand 0
```

* Analysis results on a distributed context on an example matrix
```sh
mpirun -np 6 ./pastix_distributed/example/analyze -3 ./matrice/1138_bus.mtx -v4 -t 4 -i iparm_allcand 0
```

* Factorization on a shared memory context on an example matrix
```sh
./pastix_sharedM/example/bench_facto -3 ./matrice/1138_bus.mtx -v4 -i iparm_allcand 0
```
* Analysis results on a shared memory context
```sh
cd $ARTIFACTS_DIR/scripts
./basic_forloop_sharedM.sh
```

* Analysis results on a distributed context
```sh
cd $ARTIFACTS_DIR/scripts
./basic_forloop_distributed.sh
```

* Factorization time on a shared memory context
```sh
cd $ARTIFACTS_DIR/scripts
./run_all_matrix_factor.sh
```

* Generate plots
```sh
cd $ARTIFACTS_DIR/raw_results
Rscript ./CombineData_Plot.R
```
