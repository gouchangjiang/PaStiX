#!/usr/bin/env bash
#SBATCH -J pastix_pmap
#SBATCH -N 1
#SBATCH --ntasks-per-node=24
#SBATCH -n 24
#SBATCH -o pastix_pmap%j.out
#SBATCH -e pastix_pmap%j.err
#SBATCH --time=23:59:59
##SBATCH -p longq
##SBATCH --mem=120Gb

# Change this line to your own directory
cd ./scripts/

./run_one_matrix_factor.sh nd24k                -f 0 --mm ../matrice/nd24k.mtx
./run_one_matrix_factor.sh audikw_1             -f 0 --mm ../matrice/audikw_1.mtx
./run_one_matrix_factor.sh inline_1             -f 0 --mm ../matrice/inline_1.mtx
./run_one_matrix_factor.sh ldoor                -f 0 --mm ../matrice/ldoor.mtx
./run_one_matrix_factor.sh sparsine             -f 1 --mm ../matrice/sparsine.mtx
./run_one_matrix_factor.sh bone010              -f 0 --mm ../matrice/bone010.mtx
./run_one_matrix_factor.sh boneS10              -f 0 --mm ../matrice/boneS10.mtx
./run_one_matrix_factor.sh 3Dspectralwave       -f 1 --mm ../matrice/3Dspectralwave.mtx
./run_one_matrix_factor.sh 3Dspectralwave2      -f 1 --mm ../matrice/3Dspectralwave2.mtx
./run_one_matrix_factor.sh fem_hifreq_circuit   -f 2 --mm ../matrice/fem_hifreq_circuit.mtx
./run_one_matrix_factor.sh atmosmodd            -f 2 --mm ../matrice/atmosmodd.mtx
./run_one_matrix_factor.sh atmosmodl            -f 2 --mm ../matrice/atmosmodl.mtx
./run_one_matrix_factor.sh RM07R                -f 2 --mm ../matrice/RM07R.mtx
./run_one_matrix_factor.sh dielFilterV2clx      -f 2 --mm ../matrice/dielFilterV2clx.mtx
./run_one_matrix_factor.sh dielFilterV3clx      -f 2 --mm ../matrice/dielFilterV3clx/dielFilterV3clx.mtx
./run_one_matrix_factor.sh Serena               -f 0 --mm ../matrice/Serena.mtx
./run_one_matrix_factor.sh Emilia_923           -f 0 --mm ../matrice/Emilia_923.mtx
./run_one_matrix_factor.sh Fault_639            -f 0 --mm ../matrice/Fault_639.mtx
./run_one_matrix_factor.sh Flan_1565            -f 0 --mm ../matrice/Flan_1565.mtx
./run_one_matrix_factor.sh Geo_1438             -f 0 --mm ../matrice/Geo_1438.mtx
./run_one_matrix_factor.sh Hook_1498            -f 0 --mm ../matrice/Hook_1498.mtx
./run_one_matrix_factor.sh StocF-1465           -f 0 --mm ../matrice/StocF-1465.mtx
./run_one_matrix_factor.sh Cube_Coup_dt0        -f 1 --mm ../matrice/Cube_Coup_dt0.mtx
./run_one_matrix_factor.sh Long_Coup_dt0        -f 1 --mm ../matrice/Long_Coup_dt0.mtx
./run_one_matrix_factor.sh CurlCurl_3           -f 1 --mm ../matrice/CurlCurl_3.mtx
./run_one_matrix_factor.sh CurlCurl_4           -f 1 --mm ../matrice/CurlCurl_4.mtx
./run_one_matrix_factor.sh Transport            -f 2 --mm ../matrice/Transport.mtx
./run_one_matrix_factor.sh ML_Geer              -f 2 --mm ../matrice/ML_Geer.mtx
./run_one_matrix_factor.sh Bump_2911            -f 0 --mm ../matrice/Bump_2911.mtx
./run_one_matrix_factor.sh PFlow_742            -f 0 --mm ../matrice/PFlow_742.mtx
./run_one_matrix_factor.sh bundle_adj           -f 0 --mm ../matrice/bundle_adj.mtx
./run_one_matrix_factor.sh cage13               -f 2 --mm ../matrice/cage13.mtx
./run_one_matrix_factor.sh nlpkkt80             -f 1 --mm ../matrice/nlpkkt80.mtx
