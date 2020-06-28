#!/usr/bin/env bash
#SBATCH -J pastix_pmap
#SBATCH -N 1
#SBATCH --ntasks-per-node=24
#SBATCH -n 24
#SBATCH -o pastix_pmap%j.out
#SBATCH -e pastix_pmap%j.err
#SBATCH --time=23:59:59
#####SBATCH -p court_brise
#SBATCH --mem=120Gb

module purge
module load slurm
module load build/cmake/3.15.3
module load compiler/gcc/9.2.0
module load linalg/mkl/2019_update4
module load mpi/openmpi/4.0.2
module load compiler/cuda/10.1
module load hardware/hwloc/1.11.13
module load trace/eztrace/1.1-8

module load partitioning/metis/int64/5.1.0
module load partitioning/scotch/int64/6.0.9

module load runtime/parsec/master/mpi
module load runtime/starpu/1.3.3/mpi

./basic_forloop_distributed.sh
