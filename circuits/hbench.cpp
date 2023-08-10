#include <bitset>
#include <chrono>
#include <cmath>
#include <iostream>

#include "QuEST.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define QREG_DEFAULT 36
#define TARGET_DEFAULT 0
#define NGATES_DEFAULT 100

#define QREG_MAX 32
#define PRECISION 1E-10


using namespace std;

bool operator==(Complex const& lhs, Complex const& rhs);
void print_qureg(Qureg qureg);

void set_args(int argc, char* argv[], int& qreg_size, int& target_idx, int& ngates);
int set_verbose();


int main(int argc, char *argv[]) {
  // Set number of qubits and verbosity
  int qreg_size = QREG_DEFAULT;
  int target_idx = TARGET_DEFAULT;
  int ngates = NGATES_DEFAULT;

  set_args(argc, argv, qreg_size, target_idx, ngates);
  int verbose = set_verbose();

  // Prepare the hardware-agnostic QuEST environment
  QuESTEnv env = createQuESTEnv();

  if (env.rank == 0 && verbose) {
    cout << "Verbose is ON" << endl;
    cout << "No. processes: " << env.numRanks << endl; 
    cout << "No. qubits: " << qreg_size << endl;
    cout << "Non-blocking exchange flag: " << nonBlockingExchangeFlag() << endl;
  }

  Qureg qureg = createQureg(qreg_size, env);
  initZeroState(qureg);

  // Sync and start timer
  syncQuESTEnv(env);
  auto tstart = chrono::steady_clock::now();

  // Run QFT with cache blocking
  for (int i = 0; i < ngates; i++)
    hadamard(qureg, target_idx);
  
  // Sync and stop timer
  syncQuESTEnv(env);
  auto tstop = chrono::steady_clock::now();

  double tdiff = chrono::duration<double, milli>(tstop - tstart).count();

  if (env.rank == 0) {
    if (verbose) 
      cout << "Time taken: " << tdiff << " ms" << endl;
    else 
      cout << tdiff << endl;
  }
  
  // Free memory
  destroyQureg(qureg, env);
  destroyQuESTEnv(env);

  return 0;
}


void print_qureg(Qureg qureg) {
  int numStates = 1 << qureg.numQubitsRepresented;
  for (int i = 0; i < numStates; i++) {
    Complex amp = getAmp(qureg, i);
    bitset<QREG_MAX> ibits(i);

    cout << "Probability of |" << ibits << ">: ";
    printf("%.8f + %.8fi\n", amp.real, amp.imag);
  }
}


bool operator==(Complex const& lhs, Complex const& rhs) {
  return (fabs(lhs.real - rhs.real) < PRECISION) &&
    (fabs(lhs.imag - rhs.imag) < PRECISION);
}


void set_args(int argc, char* argv[], int& qreg_size, int& target_idx, int& ngates) {
  for (int i = 1; i < argc; i++) {
    string arg = argv[i];
    if (arg == "-q") {
      qreg_size = atoi(argv[++i]);
    } else if (arg == "-t") {
      target_idx = atoi(argv[++i]);
    } else if (arg == "-n") {
      ngates = atoi(argv[++i]);
    } else {
      string message = "Error: Unknown argument '" + arg + 
        "'! Use: ./bin -q $NQUBITS";
      throw invalid_argument(message);
    }
  }
}

int set_verbose() {
  const char* tmp = getenv("VERBOSE");
  string verbose_str(tmp ? tmp : "");
  if (verbose_str == "1")
    return 1;
  else
    return 0;
}
