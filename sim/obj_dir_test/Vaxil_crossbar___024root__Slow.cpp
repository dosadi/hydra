// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxil_crossbar.h for the primary calling header

#include "Vaxil_crossbar__pch.h"
#include "Vaxil_crossbar__Syms.h"
#include "Vaxil_crossbar___024root.h"

void Vaxil_crossbar___024root___ctor_var_reset(Vaxil_crossbar___024root* vlSelf);

Vaxil_crossbar___024root::Vaxil_crossbar___024root(Vaxil_crossbar__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vaxil_crossbar___024root___ctor_var_reset(this);
}

void Vaxil_crossbar___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vaxil_crossbar___024root::~Vaxil_crossbar___024root() {
}
