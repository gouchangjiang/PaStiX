#!/bin/bash

families=(
    Fluorem
    vanHeukelum
    Schenk
    Bourchtein
    Bodendiek
    HB
    Nasa
    Boeing
    FIDAP
    Mulvey
    Okunbor
    Rothberg
    Simon
    Cunningham
    Pothen
    Norris
    ND
    Schenk_AFE
    ACUSIM
    Bai
    Oberwolfach
    Cannizzo
    GHS_psdef
    DNVS
    MathWorks
    Lourakis
    Bates
    Schmid
    Bindel
    Pajek
    GHS_indef
    AMD
    Cylshell
    INPRO
    UTEP
    BenElechi
    Wissgott
    McRae
    Castrillon
    CEMW
    TKK
    Um
    JGD_BIBD
    JGD_Trefethen
    Botonakis
    MaxPlanck
    Williams
    Janna
    Mazaheri
    indexme.sh
    Andrews
    Dziekonski
    Sinclair
    Lee
)

names=(
    3Dspectralwave
    3Dspectralwave2
    atmosmodd
    atmosmodl
    audikw_1
    bone010
    boneS10
    bundle_adj
    Bump_2911
    cage13
    Cube_Coup_dt0
    CurlCurl_3
    CurlCurl_4
    dielFilterV2clx
    dielFilterV3clx
    Emilia_923
    Fault_639
    fem_hifreq_circuit
    Flan_1565
    Geo_1438
    Hook_1498
    inline_1
    ldoor
    Long_Coup_dt0
    ML_Geer
    nd24k
    nlpkkt80
    PFlow_742
    RM07R
    Serena
    sparsine
    StocF-1465
    Transport
)

if [ ! -d archives ]; then
   mkdir archives
fi

for it in `seq 0 $((${#names[*]}-1))`
do
    i=${names[$it]}
    echo "Searching for $i"

    if [ -f ../matrice/${i%%.*}.mtx ]; then
	echo "Already here"
    else
	for jt in `seq 0 $((${#families[*]}-1))`
	do
	    j=${families[$jt]}
	    path=https://suitesparse-collection-website.herokuapp.com/MM/$j/${i%%.*}.tar.gz
            wget $path 2> /dev/null
	done
	if [ -f ${i%%.*}.tar.gz ]; then
	    mv ${i%%.*}.tar.gz archives

	    file=archives/${i%%.*}.tar.gz
	    tar xvf $file
	    mv ${i%%.*}/${i%%.*}.mtx ../matrice/
	    rm -rf ${i%%.*}
	else
	    echo "File ${i%%.*}.tar.gz not found"
	fi
    fi
done
