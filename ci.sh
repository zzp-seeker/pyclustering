#!/bin/bash


run_build_ccore_job() {
	echo "[CI Job] CCORE (C++ code building):"
	echo "- Build CCORE library."
	
	#install requirement for the job
	sudo apt-get install -qq g++-4.8
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
	
	# build ccore library
	cd ccore/
	make ccore
	
	if [ $? -eq 0 ] ; then
		echo "Building CCORE library: SUCCESS."
	else
		echo "Building CCORE library: FAILURE."
		exit 1
	fi
}


run_ut_ccore_job() {
	echo "[CI Job] UT CCORE (C++ code unit-testing of CCORE library):"
	echo "- Build C++ unit-test project for CCORE library."
	echo "- Run CCORE library unit-tests."
	
	# install requirements for the job
	sudo apt-get install -qq g++-4.8
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
	sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-4.8 50
  
	pip install cpp-coveralls
	
	# build unit-test project
	cd ccore/
	make ut

	if [ $? -eq 0 ] ; then
		echo "Building of CCORE unit-test project: SUCCESS."
	else
		echo "Building of CCORE unit-test project: FAILURE."
		exit 1
	fi

	# run unit-tests and obtain code coverage
	make utrun
	coveralls --exclude tst/ --exclude tools/ --gcov-options '\-lp'
}


run_valgrind_ccore_job() {
	echo "[CI Job]: VALGRIND CCORE (C++ code valgrind checking):"
	echo "- Run unit-tests of pyclustering."
	echo "- Memory leakage detection."
	
	# install requirements for the job
	sudo apt-get install -qq g++-4.8
	sudo apt-get install -qq valgrind
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
	
	# build unit-test project
	cd ccore/
	make ut
	
	if [ $? -eq 0 ] ; then
		echo "Building of CCORE unit-test project: SUCCESS."
	else
		echo "Building of CCORE unit-test project: FAILURE."
		exit 1
	fi
	
	# run unit-tests and check for memory leaks
	cd tst/
	valgrind --error-exitcode=42 --leak-check=full ./utcore.exe
}


run_ut_pyclustering_job() {
	echo "[CI Job]: UT PYCLUSTERING (Python code unit-testing):"
	echo "- Run unit-tests of pyclustering."
	echo "- Measure code coverage."

	# install requirements for the job
	install_miniconda
	pip install coveralls
	
	# set path to the tested library
	PYTHONPATH=`pwd`
	export PYTHONPATH=${PYTHONPATH}

	# run unit-tests and obtain coverage results
	coverage run --source=pyclustering --omit='pyclustering/*/tests/*,pyclustering/*/examples/*,pyclustering/ut/*' pyclustering/ut/__init__.py
	coveralls
}


install_miniconda() {
	wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
	
	bash miniconda.sh -b -p $HOME/miniconda
	
	export PATH="$HOME/miniconda/bin:$PATH"
	hash -r
	
	conda config --set always_yes yes --set changeps1 no
	conda update -q conda
	
	conda install libgfortran
	conda create -q -n test-environment python=3.4 numpy scipy matplotlib Pillow
	source activate test-environment
}


set -e
set -x

case $CI_JOB in
	BUILD_CCORE) 
		run_build_ccore_job ;;
		
	UT_CCORE) 
		run_ut_ccore_job ;;
	
	VALGRIND_CCORE)
		run_valgrind_ccore_job ;;
	
	UT_PYCLUSTERING) 
		run_ut_pyclustering_job ;;
		
	*)
		echo "[CI Job] Unknown target $CI_JOB"
		exit 1 ;;
esac
