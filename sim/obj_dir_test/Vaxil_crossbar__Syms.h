// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VAXIL_CROSSBAR__SYMS_H_
#define VERILATED_VAXIL_CROSSBAR__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vaxil_crossbar.h"

// INCLUDE MODULE CLASSES
#include "Vaxil_crossbar___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vaxil_crossbar__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vaxil_crossbar* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vaxil_crossbar___024root       TOP;

    // CONSTRUCTORS
    Vaxil_crossbar__Syms(VerilatedContext* contextp, const char* namep, Vaxil_crossbar* modelp);
    ~Vaxil_crossbar__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
