// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxil_crossbar.h for the primary calling header

#include "Vaxil_crossbar__pch.h"
#include "Vaxil_crossbar__Syms.h"
#include "Vaxil_crossbar___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__stl(Vaxil_crossbar___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_triggers__stl(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_triggers__stl\n"); );
    // Body
    vlSelf->__VstlTriggered.set(0U, (IData)(vlSelf->__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxil_crossbar___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
