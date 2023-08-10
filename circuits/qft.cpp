#include <bitset>
#include <chrono>
#include <cmath>
#include <iostream>

#include "QuEST.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define QREG_DEFAULT 24
#define QREG_MAX 32
#define METHOD_DEFAULT QFT::standard
#define BLOCKING_DEFAULT 32

#define PRECISION 1E-10


using namespace std;

enum class QFT { standard, blocking, builtin };

void qft_standard(Qureg qureg);
void qft_blocking(Qureg qureg, int blockingQubits);
void qft_builtin(Qureg qureg);

bool operator==(Complex const& lhs, Complex const& rhs);
void validate_result(QuESTEnv env, Qureg& qureg);
void print_qureg(Qureg qureg);

void set_args(int argc, char* argv[], int& qreg_size, int& blocking_qubits, QFT& method);
int set_verbose();


int main(int argc, char *argv[]) {
  // Set number of qubits and verbosity
  int qreg_size = QREG_DEFAULT;
  int blocking_qubits = BLOCKING_DEFAULT;
  QFT method = METHOD_DEFAULT;

  set_args(argc, argv, qreg_size, blocking_qubits, method);
  int verbose = set_verbose();

  // Prepare the hardware-agnostic QuEST environment
  QuESTEnv env = createQuESTEnv();

  if (env.rank == 0 && verbose) {
    cout << "Verbose is ON" << endl;
    cout << "No. processes: " << env.numRanks << endl; 
    cout << "No. qubits: " << qreg_size << endl;
    cout << "Method: ";
    switch(method) {
      case QFT::standard : cout << "standard" << endl; break;
      case QFT::blocking : cout << "blocking" << endl; break;
      case QFT::builtin  : cout << "builtin"  << endl; break;
    }
    cout << "Non-blocking exchange flag: " << nonBlockingExchangeFlag() << endl;
  }

  Qureg qureg = createQureg(qreg_size, env);
  initZeroState(qureg);

  // Sync and start timer
  syncQuESTEnv(env);
  auto tstart = chrono::steady_clock::now();

  // Run QFT based on selected method
  switch(method) {
      case QFT::standard : qft_standard(qureg); break;
      case QFT::blocking : qft_blocking(qureg, blocking_qubits); break;
      case QFT::builtin  : qft_builtin(qureg); break;
    }
  
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

  // Validate whether all coefficients are the same
  if (verbose)
    validate_result(env, qureg);
  
  // Free memory
  destroyQureg(qureg, env);
  destroyQuESTEnv(env);

  return 0;
}


void crot(Qureg qureg, int targetQubit, int controlQubit, int k) {
  unsigned long frac = 1 << k;
  controlledPhaseShift(qureg, targetQubit, controlQubit, 2 * M_PI / frac);
}

void multi_crot(Qureg qureg, int targetQubit) {
  for (int i = 2; i <= qureg.numQubitsRepresented - targetQubit; i++)
    crot(qureg, targetQubit, targetQubit + i - 1, i);
}

void inverse_multi_crot(Qureg qureg, int targetQubit) {
  for (int i = 2; i <= targetQubit + 1; i++)
    crot(qureg, targetQubit, targetQubit - i + 1, i);
}

void partial_qft(Qureg qureg, int* qubits, int numQubits, int stopQubit) {
  // reverse list of target qubits due to different convention
  for (int i = 0; i < numQubits / 2; i++) {
    int temp = qubits[i];
    qubits[i] = qubits[numQubits - i - 1];
    qubits[numQubits - i - 1] = temp;
  }

  stopQubit = numQubits - stopQubit;

  for (int q = numQubits - 1; q >= stopQubit; q--) {
    hadamard(qureg, qubits[q]);

    if (q == 0)
        break;
        
    int numRegs = 2;
    int numQubitsPerReg[2] = {q, 1};
    int regs[100]; // [q+1];
    for (int i = 0; i < q + 1; i++)
        regs[i] = qubits[i]; // qubits[q] is in own register
        
    int numParams = 1;
    qreal params[1] = { M_PI / (1 << q) };
        
    applyParamNamedPhaseFuncOverrides(
      qureg, regs, numQubitsPerReg, numRegs, 
      UNSIGNED, SCALED_PRODUCT, params, numParams, 
      NULL, NULL, 0);
  } 
}


void swap_qureg(Qureg qureg) {
  int n = qureg.numQubitsRepresented;
  for (int i = 0; i < n / 2; i++)
    swapGate(qureg, i, n - i - 1);
}

void qft_standard(Qureg qureg) {

  // for (int i = 0; i < qureg.numQubitsRepresented; i++) {
  //   int qubits[100];
  //   for (int j = i; j < qureg.numQubitsRepresented; j++) {
  //     qubits[j - i] = j;
  //   }

  //   multi_crot_opt(qureg, qubits, qureg.numQubitsRepresented - i);
  // }

  int qubits[100];
  for (int i = 0; i < qureg.numQubitsRepresented; i++) {
    qubits[i] = i;
  }

  partial_qft(qureg, qubits, qureg.numQubitsRepresented, qureg.numQubitsRepresented);

  swap_qureg(qureg);
}

// cab_qubits > qureg_size / 2
void qft_blocking(Qureg qureg, int blockingQubits) {
  // for (int i = 0; i < cab_qubits; i++) {
  //   hadamard(qureg, i);
  //   multi_crot(qureg, i);
  // }

  int qubits[100];
  for (int i = 0; i < qureg.numQubitsRepresented; i++) {
    qubits[i] = i;
  }

  partial_qft(qureg, qubits, qureg.numQubitsRepresented, blockingQubits);


  swap_qureg(qureg);


  for (int i = 0; i < qureg.numQubitsRepresented - blockingQubits; i++) {
    qubits[i] = qureg.numQubitsRepresented - blockingQubits - i - 1;
  }

  partial_qft(qureg, qubits, qureg.numQubitsRepresented - blockingQubits, qureg.numQubitsRepresented - blockingQubits);

  // for (int i = qureg.numQubitsRepresented - cab_qubits - 1; i >= 0; i--) {
  //   hadamard(qureg, i);
  //   inverse_multi_crot(qureg, i);
  // }
}

void qft_builtin(Qureg qureg) {
  // int n_qubits = qureg.numQubitsRepresented;
  // int* target_qubits = new int(n_qubits);
  // for (int i = 0; i < n_qubits; i++)
  //   target_qubits[i] = i;


  applyFullQFT(qureg);
}

// cout << "Initialised: target_qubits[" << n_qubits - 1 << "] = " << target_qubits[n_qubits - 1] << endl;

bool operator==(Complex const& lhs, Complex const& rhs) {
  return (fabs(lhs.real - rhs.real) < PRECISION) &&
    (fabs(lhs.imag - rhs.imag) < PRECISION);
}

void validate_result(QuESTEnv env, Qureg& qureg) {
  unsigned long numStates = 1LL << qureg.numQubitsRepresented;
  Complex amp0 = getAmp(qureg, 0);
  Complex ampN = getAmp(qureg, numStates - 1);
  // bool isValid = true;

  Complex exp_amp;
  exp_amp.real = pow(2, -(double)qureg.numQubitsRepresented / 2.0);
  exp_amp.imag = 0.0;
  // int i;
  // for (i = 1; i < numStates && isValid; i++)
  //   isValid = getAmp(qureg, i) == ampZero;

  if (env.rank == 0) {
      cout << "Psi[0] = "   << amp0.real << " + " << amp0.imag << "i" << endl;
      cout << "Psi[N-1] = " << ampN.real << " + " << ampN.imag << "i" << endl;
      cout << "Expected = " << exp_amp.real << " + " << exp_amp.imag << "i" << endl;
    if (amp0 == exp_amp && ampN == exp_amp) 
      cout << "Result valid" << endl;
    else
      cout << "Result invalid" << endl;
    // cout << "Checked " << i << " entries" << endl;
  }
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


void set_args(int argc, char* argv[], int& qreg_size, int& blocking_qubits, QFT& method) {
  for (int i = 1; i < argc; i++) {
    string arg = argv[i];
    if (arg == "-q") {
      qreg_size = atoi(argv[++i]);
    } else if (arg == "-b") {
      blocking_qubits = atoi(argv[++i]);
    } else if (arg == "-m") {
      string str_method = argv[++i];
      if (str_method == "standard") {
        method = QFT::standard;
      } else if (str_method == "blocking") {
        method = QFT::blocking;
      } else if (str_method == "builtin") {
        method = QFT::builtin;
      } else {
        string message_unknown_method = "Error: Unknown QFT method '" + arg + 
        "'! Use either: [standard]/blocking/builtin";
        throw invalid_argument(message_unknown_method);
      }
    } else {
      string message_unknown_arg = "Error: Unknown argument '" + arg + 
        "'! Use: ./bin -q $NQUBITS -b $BLOCKING_QUBITS$ -m $METHOD";
      throw invalid_argument(message_unknown_arg);
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


