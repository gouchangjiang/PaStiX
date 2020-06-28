#!/usr/bin/env bash
export STARPU_HOSTNAME=`echo $HOSTNAME | sed 's/[0-9]//g'`

###
#
# Change those lines to your environment
#
###
ARTIFACTDIR=$PWD
MATRIXDIR=$ARTIFACTDIR/matrice
BINARY=$ARTIFACTDIR/pastix_distributed/example/bench_facto
TESTDIR=$ARTIFACTDIR/raw_results/shared
MPI=mpirun
MACHINENAME=miriel
NBCORES=6
NPROC=4
###

names=(
    nd24k
    audikw_1          
    inline_1          
    ldoor             
    sparsine          
    bone010           
    boneS10           
    3Dspectralwave    
    3Dspectralwave2
    fem_hifreq_circuit
    atmosmodd         
    atmosmodl         
    RM07R             
    dielFilterV2clx   
    dielFilterV3clx
    Serena            
    Emilia_923        
    Fault_639         
    Flan_1565         
    Geo_1438          
    Hook_1498         
    StocF-1465        
    Cube_Coup_dt0     
    Long_Coup_dt0     
    CurlCurl_3        
    CurlCurl_4        
    Transport         
    ML_Geer           
    Bump_2911         
    PFlow_742         
    bundle_adj        
    cage13            
    nlpkkt80                     
)

commands=(
    "-f 0 --mm ${MATRIXDIR}/nd24k.mtx"
    "-f 0 --mm ${MATRIXDIR}/audikw_1.mtx"
    "-f 0 --mm ${MATRIXDIR}/inline_1.mtx"
    "-f 0 --mm ${MATRIXDIR}/ldoor.mtx"
    "-f 1 --mm ${MATRIXDIR}/sparsine.mtx"
    "-f 0 --mm ${MATRIXDIR}/bone010.mtx"
    "-f 0 --mm ${MATRIXDIR}/boneS10.mtx"
    "-f 1 --mm ${MATRIXDIR}/3Dspectralwave.mtx"
    "-f 1 --mm ${MATRIXDIR}/3Dspectralwave2.mtx"
    "-f 2 --mm ${MATRIXDIR}/fem_hifreq_circuit.mtx"
    "-f 2 --mm ${MATRIXDIR}/atmosmodd.mtx"
    "-f 2 --mm ${MATRIXDIR}/atmosmodl.mtx"
    "-f 2 --mm ${MATRIXDIR}/RM07R.mtx"
    "-f 2 --mm ${MATRIXDIR}/dielFilterV2clx.mtx"
    "-f 2 --mm ${MATRIXDIR}/dielFilterV3clx/dielFilterV3clx.mtx"
    "-f 0 --mm ${MATRIXDIR}/Serena.mtx"
    "-f 0 --mm ${MATRIXDIR}/Emilia_923.mtx"
    "-f 0 --mm ${MATRIXDIR}/Fault_639.mtx"
    "-f 0 --mm ${MATRIXDIR}/Flan_1565.mtx"
    "-f 0 --mm ${MATRIXDIR}/Geo_1438.mtx"
    "-f 0 --mm ${MATRIXDIR}/Hook_1498.mtx"
    "-f 0 --mm ${MATRIXDIR}/StocF-1465.mtx"
    "-f 1 --mm ${MATRIXDIR}/Cube_Coup_dt0.mtx"
    "-f 1 --mm ${MATRIXDIR}/Long_Coup_dt0.mtx"
    "-f 1 --mm ${MATRIXDIR}/CurlCurl_3.mtx"
    "-f 1 --mm ${MATRIXDIR}/CurlCurl_4.mtx"
    "-f 2 --mm ${MATRIXDIR}/Transport.mtx"
    "-f 2 --mm ${MATRIXDIR}/ML_Geer.mtx"
    "-f 0 --mm ${MATRIXDIR}/Bump_2911.mtx"
    "-f 0 --mm ${MATRIXDIR}/PFlow_742.mtx"
    "-f 0 --mm ${MATRIXDIR}/bundle_adj.mtx"
    "-f 2 --mm ${MATRIXDIR}/cage13.mtx"
    "-f 1 --mm ${MATRIXDIR}/nlpkkt80.mtx"
)
## We removed this extra matrix not available on MatrixMarket
## "-f 0 --mm /projets/hiepacs/matrices.XL/10Millions/10M_Matrice"

MPINODENUMBER=" -np $NPROC --map-by node:PE=$NBCORES"
dist1d="-i iparm_tasks2d_level 0"
dist2d="-i iparm_tasks2d_width"

min=288
maxcoef=3
max=$((min * maxcoef))

# 1D
s=1
bsize="-s $s -i iparm_min_blocksize $min -i iparm_max_blocksize $max $dist1d"

for i in `seq 0 $((${#names[*]}-1))`
do
    MTXNAME=${names[$i]}
    COMMAND=${commands[$i]}

    OPTIONS="$COMMAND -v4 -i iparm_ordering_default 0 -i iparm_scotch_cmin 20 -t $NBCORES"

    cd $TESTDIR
    mkdir -p pmap-${MACHINENAME}-real-${NPROC}M${NBCORES}/$MTXNAME
    cd pmap-${MACHINENAME}-real-${NPROC}M${NBCORES}/$MTXNAME

    cand=0
    allcand="-i iparm_allcand $cand"
    fname="${MACHINENAME}_${MTXNAME}_sched${s}_1d_bs${min}_${max}_cand${cand}.log"

    # Force the first test if the heuristic failed the previous time we ran it
    if [ ! -s $mapfile ]
    then
	rm -f $fname
    fi

    # Perform the first test (PropMap) only if the output file does not exist
    if [ ! -s $fname ]
    then
	echo $MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname
	$MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname 2>&1

    rm pastix-*/*.dot
    rm pastix-*/*.svg
    fi
    rm -f core*

    # Let's compare with AllCand heuristic
    cand=1
    fname="${MACHINENAME}_${MTXNAME}_sched${s}_1d_bs${min}_${max}_cand${cand}.log"
    allcand="-i iparm_allcand $cand"
    if [ ! -s $fname ]
    then
	echo $MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname
	$MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname 2>&1

    rm pastix-*/*.dot
    rm pastix-*/*.svg
    fi
    rm -f core*

    cand=3
    fname="${MACHINENAME}_${MTXNAME}_sched${s}_1d_bs${min}_${max}_cand${cand}.log"
    allcand="-i iparm_allcand $cand"
    if [ ! -s $fname ]
    then
	echo $MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname
	$MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname 2>&1

    rm pastix-*/*.dot
    rm pastix-*/*.svg
    fi
    rm -f core*

    cand=4
    fname="${MACHINENAME}_${MTXNAME}_sched${s}_1d_bs${min}_${max}_cand${cand}.log"
    allcand="-i iparm_allcand $cand"
    if [ ! -s $fname ]
    then
        echo $MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname
        $MPI $MPINODENUMBER $BINARY $OPTIONS $bsize $dist1d $allcand >> $fname 2>&1

    rm pastix-*/*.dot
    rm pastix-*/*.svg
    fi
    rm -f core*
done
