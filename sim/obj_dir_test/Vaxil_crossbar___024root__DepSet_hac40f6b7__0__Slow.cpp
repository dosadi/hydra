// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxil_crossbar.h for the primary calling header

#include "Vaxil_crossbar__pch.h"
#include "Vaxil_crossbar___024root.h"

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_static(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_initial(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
    vlSelf->__Vtrigprevexpr___TOP__rst_n__0 = vlSelf->rst_n;
}

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_final(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__stl(Vaxil_crossbar___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vaxil_crossbar___024root___eval_phase__stl(Vaxil_crossbar___024root* vlSelf);

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_settle(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vaxil_crossbar___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../rtl/axil_crossbar.sv", 9, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vaxil_crossbar___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__stl(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxil_crossbar___024root___stl_sequent__TOP__0(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___stl_sequent__TOP__0\n"); );
    // Init
    CData/*3:0*/ axil_crossbar__DOT__aw_request;
    axil_crossbar__DOT__aw_request = 0;
    CData/*3:0*/ axil_crossbar__DOT__ar_request;
    axil_crossbar__DOT__ar_request = 0;
    IData/*31:0*/ axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx;
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx = 0;
    IData/*31:0*/ axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx;
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx = 0;
    // Body
    vlSelf->m_bvalid = 0U;
    vlSelf->m_bresp = 0U;
    vlSelf->s_bready = 0U;
    if ((1U & (IData)(vlSelf->s_bvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id 
            = (3U & (IData)(vlSelf->axil_crossbar__DOT__w_owner));
        vlSelf->m_bvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))) 
                             & (IData)(vlSelf->m_bvalid)) 
                            | (0xfU & ((1U & (IData)(vlSelf->s_bvalid)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))));
        vlSelf->m_bresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_bresp)) 
                           | (0xffU & ((3U & (IData)(vlSelf->s_bresp)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))));
        vlSelf->s_bready = ((0xeU & (IData)(vlSelf->s_bready)) 
                            | (1U & ((IData)(vlSelf->m_bready) 
                                     >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))));
    }
    if ((2U & (IData)(vlSelf->s_bvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__w_owner) 
                     >> 2U));
        vlSelf->m_bvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))) 
                             & (IData)(vlSelf->m_bvalid)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_bvalid) 
                                              >> 1U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))));
        vlSelf->m_bresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_bresp)) 
                           | (0xffU & ((3U & ((IData)(vlSelf->s_bresp) 
                                              >> 2U)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))));
        vlSelf->s_bready = ((0xdU & (IData)(vlSelf->s_bready)) 
                            | (2U & (((IData)(vlSelf->m_bready) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id)) 
                                     << 1U)));
    }
    if ((4U & (IData)(vlSelf->s_bvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__w_owner) 
                     >> 4U));
        vlSelf->m_bvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))) 
                             & (IData)(vlSelf->m_bvalid)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_bvalid) 
                                              >> 2U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))));
        vlSelf->m_bresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_bresp)) 
                           | (0xffU & ((3U & ((IData)(vlSelf->s_bresp) 
                                              >> 4U)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))));
        vlSelf->s_bready = ((0xbU & (IData)(vlSelf->s_bready)) 
                            | (4U & (((IData)(vlSelf->m_bready) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id)) 
                                     << 2U)));
    }
    if ((8U & (IData)(vlSelf->s_bvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__w_owner) 
                     >> 6U));
        vlSelf->m_bvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))) 
                             & (IData)(vlSelf->m_bvalid)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_bvalid) 
                                              >> 3U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id))));
        vlSelf->m_bresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_bresp)) 
                           | (0xffU & ((3U & ((IData)(vlSelf->s_bresp) 
                                              >> 6U)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id, 1U)))));
        vlSelf->s_bready = ((7U & (IData)(vlSelf->s_bready)) 
                            | (8U & (((IData)(vlSelf->m_bready) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id)) 
                                     << 3U)));
    }
    vlSelf->m_rvalid = 0U;
    vlSelf->m_rdata[0U] = 0U;
    vlSelf->m_rdata[1U] = 0U;
    vlSelf->m_rdata[2U] = 0U;
    vlSelf->m_rdata[3U] = 0U;
    vlSelf->m_rresp = 0U;
    vlSelf->s_rready = 0U;
    if ((1U & (IData)(vlSelf->s_rvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id 
            = (3U & (IData)(vlSelf->axil_crossbar__DOT__r_owner));
        vlSelf->m_rvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))) 
                             & (IData)(vlSelf->m_rvalid)) 
                            | (0xfU & ((1U & (IData)(vlSelf->s_rvalid)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 5U)), vlSelf->m_rdata, 
                        vlSelf->s_rdata[0U]);
        vlSelf->m_rresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_rresp)) 
                           | (0xffU & ((3U & (IData)(vlSelf->s_rresp)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))));
        vlSelf->s_rready = ((0xeU & (IData)(vlSelf->s_rready)) 
                            | (1U & ((IData)(vlSelf->m_rready) 
                                     >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))));
    }
    if ((2U & (IData)(vlSelf->s_rvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__r_owner) 
                     >> 2U));
        vlSelf->m_rvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))) 
                             & (IData)(vlSelf->m_rvalid)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_rvalid) 
                                              >> 1U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 5U)), vlSelf->m_rdata, 
                        vlSelf->s_rdata[1U]);
        vlSelf->m_rresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_rresp)) 
                           | (0xffU & ((3U & ((IData)(vlSelf->s_rresp) 
                                              >> 2U)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))));
        vlSelf->s_rready = ((0xdU & (IData)(vlSelf->s_rready)) 
                            | (2U & (((IData)(vlSelf->m_rready) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id)) 
                                     << 1U)));
    }
    if ((4U & (IData)(vlSelf->s_rvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__r_owner) 
                     >> 4U));
        vlSelf->m_rvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))) 
                             & (IData)(vlSelf->m_rvalid)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_rvalid) 
                                              >> 2U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 5U)), vlSelf->m_rdata, 
                        vlSelf->s_rdata[2U]);
        vlSelf->m_rresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_rresp)) 
                           | (0xffU & ((3U & ((IData)(vlSelf->s_rresp) 
                                              >> 4U)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))));
        vlSelf->s_rready = ((0xbU & (IData)(vlSelf->s_rready)) 
                            | (4U & (((IData)(vlSelf->m_rready) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id)) 
                                     << 2U)));
    }
    if ((8U & (IData)(vlSelf->s_rvalid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__r_owner) 
                     >> 6U));
        vlSelf->m_rvalid = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))) 
                             & (IData)(vlSelf->m_rvalid)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_rvalid) 
                                              >> 3U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 5U)), vlSelf->m_rdata, 
                        vlSelf->s_rdata[3U]);
        vlSelf->m_rresp = (((~ ((IData)(3U) << (7U 
                                                & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))) 
                            & (IData)(vlSelf->m_rresp)) 
                           | (0xffU & ((3U & ((IData)(vlSelf->s_rresp) 
                                              >> 6U)) 
                                       << (7U & VL_SHIFTL_III(3,32,32, vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id, 1U)))));
        vlSelf->s_rready = ((7U & (IData)(vlSelf->s_rready)) 
                            | (8U & (((IData)(vlSelf->m_rready) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id)) 
                                     << 3U)));
    }
    vlSelf->s_wvalid = 0U;
    vlSelf->s_wdata[0U] = 0U;
    vlSelf->s_wdata[1U] = 0U;
    vlSelf->s_wdata[2U] = 0U;
    vlSelf->s_wdata[3U] = 0U;
    vlSelf->s_wstrb = 0U;
    vlSelf->m_wready = 0U;
    if ((1U & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id 
            = (3U & (IData)(vlSelf->axil_crossbar__DOT__w_owner));
        vlSelf->s_wvalid = ((0xeU & (IData)(vlSelf->s_wvalid)) 
                            | (1U & ((IData)(vlSelf->m_wvalid) 
                                     >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))));
        vlSelf->s_wdata[0U] = (((0U == (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U)))
                                 ? 0U : (vlSelf->m_wdata[
                                         (((IData)(0x1fU) 
                                           + (0x7fU 
                                              & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))) 
                                          >> 5U)] << 
                                         ((IData)(0x20U) 
                                          - (0x1fU 
                                             & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))))) 
                               | (vlSelf->m_wdata[(3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U) 
                                                      >> 5U))] 
                                  >> (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))));
        vlSelf->s_wstrb = ((0xfff0U & (IData)(vlSelf->s_wstrb)) 
                           | (0xfU & ((IData)(vlSelf->m_wstrb) 
                                      >> (0xfU & VL_SHIFTL_III(4,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 2U)))));
        vlSelf->m_wready = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))) 
                             & (IData)(vlSelf->m_wready)) 
                            | (0xfU & ((1U & (IData)(vlSelf->s_wready)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))));
    }
    if ((2U & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__w_owner) 
                     >> 2U));
        vlSelf->s_wvalid = ((0xdU & (IData)(vlSelf->s_wvalid)) 
                            | (2U & (((IData)(vlSelf->m_wvalid) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id)) 
                                     << 1U)));
        vlSelf->s_wdata[1U] = (((0U == (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U)))
                                 ? 0U : (vlSelf->m_wdata[
                                         (((IData)(0x1fU) 
                                           + (0x7fU 
                                              & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))) 
                                          >> 5U)] << 
                                         ((IData)(0x20U) 
                                          - (0x1fU 
                                             & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))))) 
                               | (vlSelf->m_wdata[(3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U) 
                                                      >> 5U))] 
                                  >> (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))));
        vlSelf->s_wstrb = ((0xff0fU & (IData)(vlSelf->s_wstrb)) 
                           | (0xf0U & (((IData)(vlSelf->m_wstrb) 
                                        >> (0xfU & 
                                            VL_SHIFTL_III(4,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 2U))) 
                                       << 4U)));
        vlSelf->m_wready = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))) 
                             & (IData)(vlSelf->m_wready)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_wready) 
                                              >> 1U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))));
    }
    if ((4U & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__w_owner) 
                     >> 4U));
        vlSelf->s_wvalid = ((0xbU & (IData)(vlSelf->s_wvalid)) 
                            | (4U & (((IData)(vlSelf->m_wvalid) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id)) 
                                     << 2U)));
        vlSelf->s_wdata[2U] = (((0U == (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U)))
                                 ? 0U : (vlSelf->m_wdata[
                                         (((IData)(0x1fU) 
                                           + (0x7fU 
                                              & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))) 
                                          >> 5U)] << 
                                         ((IData)(0x20U) 
                                          - (0x1fU 
                                             & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))))) 
                               | (vlSelf->m_wdata[(3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U) 
                                                      >> 5U))] 
                                  >> (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))));
        vlSelf->s_wstrb = ((0xf0ffU & (IData)(vlSelf->s_wstrb)) 
                           | (0xf00U & (((IData)(vlSelf->m_wstrb) 
                                         >> (0xfU & 
                                             VL_SHIFTL_III(4,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 2U))) 
                                        << 8U)));
        vlSelf->m_wready = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))) 
                             & (IData)(vlSelf->m_wready)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_wready) 
                                              >> 2U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))));
    }
    if ((8U & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid))) {
        vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id 
            = (3U & ((IData)(vlSelf->axil_crossbar__DOT__w_owner) 
                     >> 6U));
        vlSelf->s_wvalid = ((7U & (IData)(vlSelf->s_wvalid)) 
                            | (8U & (((IData)(vlSelf->m_wvalid) 
                                      >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id)) 
                                     << 3U)));
        vlSelf->s_wdata[3U] = (((0U == (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U)))
                                 ? 0U : (vlSelf->m_wdata[
                                         (((IData)(0x1fU) 
                                           + (0x7fU 
                                              & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))) 
                                          >> 5U)] << 
                                         ((IData)(0x20U) 
                                          - (0x1fU 
                                             & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))))) 
                               | (vlSelf->m_wdata[(3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U) 
                                                      >> 5U))] 
                                  >> (0x1fU & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 5U))));
        vlSelf->s_wstrb = ((0xfffU & (IData)(vlSelf->s_wstrb)) 
                           | (0xf000U & (((IData)(vlSelf->m_wstrb) 
                                          >> (0xfU 
                                              & VL_SHIFTL_III(4,32,32, vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id, 2U))) 
                                         << 0xcU)));
        vlSelf->m_wready = (((~ ((IData)(1U) << (3U 
                                                 & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))) 
                             & (IData)(vlSelf->m_wready)) 
                            | (0xfU & ((1U & ((IData)(vlSelf->s_wready) 
                                              >> 3U)) 
                                       << (3U & vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id))));
    }
    vlSelf->axil_crossbar__DOT__aw_grant = 0U;
    axil_crossbar__DOT__aw_request = vlSelf->m_awvalid;
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx 
        = (3U & (IData)(vlSelf->axil_crossbar__DOT__aw_priority));
    if ((1U & ((IData)(axil_crossbar__DOT__aw_request) 
               >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx)))) {
        vlSelf->axil_crossbar__DOT__aw_grant = ((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx))));
    }
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx 
        = (3U & ((IData)(1U) + (IData)(vlSelf->axil_crossbar__DOT__aw_priority)));
    if ((1U & (((IData)(axil_crossbar__DOT__aw_request) 
                >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx)) 
               & (~ (IData)((0U != (IData)(vlSelf->axil_crossbar__DOT__aw_grant))))))) {
        vlSelf->axil_crossbar__DOT__aw_grant = ((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx))));
    }
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx 
        = (3U & ((IData)(2U) + (IData)(vlSelf->axil_crossbar__DOT__aw_priority)));
    if ((1U & (((IData)(axil_crossbar__DOT__aw_request) 
                >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx)) 
               & (~ (IData)((0U != (IData)(vlSelf->axil_crossbar__DOT__aw_grant))))))) {
        vlSelf->axil_crossbar__DOT__aw_grant = ((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx))));
    }
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx 
        = (3U & ((IData)(3U) + (IData)(vlSelf->axil_crossbar__DOT__aw_priority)));
    if ((1U & (((IData)(axil_crossbar__DOT__aw_request) 
                >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx)) 
               & (~ (IData)((0U != (IData)(vlSelf->axil_crossbar__DOT__aw_grant))))))) {
        vlSelf->axil_crossbar__DOT__aw_grant = ((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx))));
    }
    vlSelf->axil_crossbar__DOT__ar_grant = 0U;
    axil_crossbar__DOT__ar_request = vlSelf->m_arvalid;
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx 
        = (3U & (IData)(vlSelf->axil_crossbar__DOT__ar_priority));
    if ((1U & ((IData)(axil_crossbar__DOT__ar_request) 
               >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx)))) {
        vlSelf->axil_crossbar__DOT__ar_grant = ((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx))));
    }
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx 
        = (3U & ((IData)(1U) + (IData)(vlSelf->axil_crossbar__DOT__ar_priority)));
    if ((1U & (((IData)(axil_crossbar__DOT__ar_request) 
                >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx)) 
               & (~ (IData)((0U != (IData)(vlSelf->axil_crossbar__DOT__ar_grant))))))) {
        vlSelf->axil_crossbar__DOT__ar_grant = ((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx))));
    }
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx 
        = (3U & ((IData)(2U) + (IData)(vlSelf->axil_crossbar__DOT__ar_priority)));
    if ((1U & (((IData)(axil_crossbar__DOT__ar_request) 
                >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx)) 
               & (~ (IData)((0U != (IData)(vlSelf->axil_crossbar__DOT__ar_grant))))))) {
        vlSelf->axil_crossbar__DOT__ar_grant = ((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx))));
    }
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx 
        = (3U & ((IData)(3U) + (IData)(vlSelf->axil_crossbar__DOT__ar_priority)));
    if ((1U & (((IData)(axil_crossbar__DOT__ar_request) 
                >> (3U & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx)) 
               & (~ (IData)((0U != (IData)(vlSelf->axil_crossbar__DOT__ar_grant))))))) {
        vlSelf->axil_crossbar__DOT__ar_grant = ((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                                                | (0xfU 
                                                   & ((IData)(1U) 
                                                      << 
                                                      (3U 
                                                       & axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx))));
    }
    vlSelf->s_awvalid = 0U;
    vlSelf->s_awaddr[0U] = 0U;
    vlSelf->s_awaddr[1U] = 0U;
    vlSelf->s_awaddr[2U] = 0U;
    vlSelf->s_awaddr[3U] = 0U;
    vlSelf->s_awprot = 0U;
    vlSelf->m_awready = 0U;
    if ((1U & (IData)(vlSelf->axil_crossbar__DOT__aw_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
            = vlSelf->m_awaddr[0U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
                goto __Vlabel1;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel1;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel1;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel1;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel1: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout;
        vlSelf->s_awvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))) 
                              & (IData)(vlSelf->s_awvalid)) 
                             | (0xfU & ((1U & (IData)(vlSelf->m_awvalid)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id), 5U)), vlSelf->s_awaddr, 
                        vlSelf->m_awaddr[0U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0 
            = (7U & (IData)(vlSelf->m_awprot));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)))))) {
            vlSelf->s_awprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_awprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))));
        }
        vlSelf->m_awready = ((0xeU & (IData)(vlSelf->m_awready)) 
                             | (1U & ((IData)(vlSelf->s_awready) 
                                      >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))));
    }
    if ((2U & (IData)(vlSelf->axil_crossbar__DOT__aw_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
            = vlSelf->m_awaddr[1U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
                goto __Vlabel2;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel2;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel2;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel2;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel2: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout;
        vlSelf->s_awvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))) 
                              & (IData)(vlSelf->s_awvalid)) 
                             | (0xfU & ((1U & ((IData)(vlSelf->m_awvalid) 
                                               >> 1U)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id), 5U)), vlSelf->s_awaddr, 
                        vlSelf->m_awaddr[1U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0 
            = (7U & ((IData)(vlSelf->m_awprot) >> 3U));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)))))) {
            vlSelf->s_awprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_awprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))));
        }
        vlSelf->m_awready = ((0xdU & (IData)(vlSelf->m_awready)) 
                             | (2U & (((IData)(vlSelf->s_awready) 
                                       >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)) 
                                      << 1U)));
    }
    if ((4U & (IData)(vlSelf->axil_crossbar__DOT__aw_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
            = vlSelf->m_awaddr[2U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
                goto __Vlabel3;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel3;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel3;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel3;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel3: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout;
        vlSelf->s_awvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))) 
                              & (IData)(vlSelf->s_awvalid)) 
                             | (0xfU & ((1U & ((IData)(vlSelf->m_awvalid) 
                                               >> 2U)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id), 5U)), vlSelf->s_awaddr, 
                        vlSelf->m_awaddr[2U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0 
            = (7U & ((IData)(vlSelf->m_awprot) >> 6U));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)))))) {
            vlSelf->s_awprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_awprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))));
        }
        vlSelf->m_awready = ((0xbU & (IData)(vlSelf->m_awready)) 
                             | (4U & (((IData)(vlSelf->s_awready) 
                                       >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)) 
                                      << 2U)));
    }
    if ((8U & (IData)(vlSelf->axil_crossbar__DOT__aw_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
            = vlSelf->m_awaddr[3U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
                goto __Vlabel4;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel4;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel4;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel4;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel4: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout;
        vlSelf->s_awvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))) 
                              & (IData)(vlSelf->s_awvalid)) 
                             | (0xfU & ((1U & ((IData)(vlSelf->m_awvalid) 
                                               >> 3U)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id), 5U)), vlSelf->s_awaddr, 
                        vlSelf->m_awaddr[3U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0 
            = (7U & ((IData)(vlSelf->m_awprot) >> 9U));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)))))) {
            vlSelf->s_awprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_awprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id))))));
        }
        vlSelf->m_awready = ((7U & (IData)(vlSelf->m_awready)) 
                             | (8U & (((IData)(vlSelf->s_awready) 
                                       >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id)) 
                                      << 3U)));
    }
    vlSelf->s_arvalid = 0U;
    vlSelf->s_araddr[0U] = 0U;
    vlSelf->s_araddr[1U] = 0U;
    vlSelf->s_araddr[2U] = 0U;
    vlSelf->s_araddr[3U] = 0U;
    vlSelf->s_arprot = 0U;
    vlSelf->m_arready = 0U;
    if ((1U & (IData)(vlSelf->axil_crossbar__DOT__ar_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
            = vlSelf->m_araddr[0U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
                goto __Vlabel5;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel5;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel5;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel5;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel5: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout;
        vlSelf->s_arvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))) 
                              & (IData)(vlSelf->s_arvalid)) 
                             | (0xfU & ((1U & (IData)(vlSelf->m_arvalid)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id), 5U)), vlSelf->s_araddr, 
                        vlSelf->m_araddr[0U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0 
            = (7U & (IData)(vlSelf->m_arprot));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)))))) {
            vlSelf->s_arprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_arprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))));
        }
        vlSelf->m_arready = ((0xeU & (IData)(vlSelf->m_arready)) 
                             | (1U & ((IData)(vlSelf->s_arready) 
                                      >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))));
    }
    if ((2U & (IData)(vlSelf->axil_crossbar__DOT__ar_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
            = vlSelf->m_araddr[1U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
                goto __Vlabel6;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel6;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel6;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel6;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel6: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout;
        vlSelf->s_arvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))) 
                              & (IData)(vlSelf->s_arvalid)) 
                             | (0xfU & ((1U & ((IData)(vlSelf->m_arvalid) 
                                               >> 1U)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id), 5U)), vlSelf->s_araddr, 
                        vlSelf->m_araddr[1U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0 
            = (7U & ((IData)(vlSelf->m_arprot) >> 3U));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)))))) {
            vlSelf->s_arprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_arprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))));
        }
        vlSelf->m_arready = ((0xdU & (IData)(vlSelf->m_arready)) 
                             | (2U & (((IData)(vlSelf->s_arready) 
                                       >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)) 
                                      << 1U)));
    }
    if ((4U & (IData)(vlSelf->axil_crossbar__DOT__ar_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
            = vlSelf->m_araddr[2U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
                goto __Vlabel7;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel7;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel7;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel7;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel7: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout;
        vlSelf->s_arvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))) 
                              & (IData)(vlSelf->s_arvalid)) 
                             | (0xfU & ((1U & ((IData)(vlSelf->m_arvalid) 
                                               >> 2U)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id), 5U)), vlSelf->s_araddr, 
                        vlSelf->m_araddr[2U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0 
            = (7U & ((IData)(vlSelf->m_arprot) >> 6U));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)))))) {
            vlSelf->s_arprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_arprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))));
        }
        vlSelf->m_arready = ((0xbU & (IData)(vlSelf->m_arready)) 
                             | (4U & (((IData)(vlSelf->s_arready) 
                                       >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)) 
                                      << 2U)));
    }
    if ((8U & (IData)(vlSelf->axil_crossbar__DOT__ar_grant))) {
        vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
            = vlSelf->m_araddr[3U];
        {
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
                goto __Vlabel8;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel8;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel8;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel8;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel8: ;
        }
        vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id 
            = vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout;
        vlSelf->s_arvalid = (((~ ((IData)(1U) << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))) 
                              & (IData)(vlSelf->s_arvalid)) 
                             | (0xfU & ((1U & ((IData)(vlSelf->m_arvalid) 
                                               >> 3U)) 
                                        << (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))));
        VL_ASSIGNSEL_WI(128,32,(0x7fU & VL_SHIFTL_III(7,32,32, (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id), 5U)), vlSelf->s_araddr, 
                        vlSelf->m_araddr[3U]);
        vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0 
            = (7U & ((IData)(vlSelf->m_arprot) >> 9U));
        if (VL_LIKELY((0xbU >= (0xfU & ((IData)(3U) 
                                        * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)))))) {
            vlSelf->s_arprot = (((~ ((IData)(7U) << 
                                     (0xfU & ((IData)(3U) 
                                              * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))) 
                                 & (IData)(vlSelf->s_arprot)) 
                                | (0xfffU & ((IData)(vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0) 
                                             << (0xfU 
                                                 & ((IData)(3U) 
                                                    * (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id))))));
        }
        vlSelf->m_arready = ((7U & (IData)(vlSelf->m_arready)) 
                             | (8U & (((IData)(vlSelf->s_arready) 
                                       >> (IData)(vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id)) 
                                      << 3U)));
    }
}

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_stl(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vaxil_crossbar___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vaxil_crossbar___024root___eval_triggers__stl(Vaxil_crossbar___024root* vlSelf);

VL_ATTR_COLD bool Vaxil_crossbar___024root___eval_phase__stl(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vaxil_crossbar___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vaxil_crossbar___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__ico(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VicoTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__act(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk or negedge rst_n)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__nba(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk or negedge rst_n)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxil_crossbar___024root___ctor_var_reset(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst_n = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(128, vlSelf->m_awaddr);
    vlSelf->m_awprot = VL_RAND_RESET_I(12);
    vlSelf->m_awvalid = VL_RAND_RESET_I(4);
    vlSelf->m_awready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->m_wdata);
    vlSelf->m_wstrb = VL_RAND_RESET_I(16);
    vlSelf->m_wvalid = VL_RAND_RESET_I(4);
    vlSelf->m_wready = VL_RAND_RESET_I(4);
    vlSelf->m_bresp = VL_RAND_RESET_I(8);
    vlSelf->m_bvalid = VL_RAND_RESET_I(4);
    vlSelf->m_bready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->m_araddr);
    vlSelf->m_arprot = VL_RAND_RESET_I(12);
    vlSelf->m_arvalid = VL_RAND_RESET_I(4);
    vlSelf->m_arready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->m_rdata);
    vlSelf->m_rresp = VL_RAND_RESET_I(8);
    vlSelf->m_rvalid = VL_RAND_RESET_I(4);
    vlSelf->m_rready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->s_awaddr);
    vlSelf->s_awprot = VL_RAND_RESET_I(12);
    vlSelf->s_awvalid = VL_RAND_RESET_I(4);
    vlSelf->s_awready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->s_wdata);
    vlSelf->s_wstrb = VL_RAND_RESET_I(16);
    vlSelf->s_wvalid = VL_RAND_RESET_I(4);
    vlSelf->s_wready = VL_RAND_RESET_I(4);
    vlSelf->s_bresp = VL_RAND_RESET_I(8);
    vlSelf->s_bvalid = VL_RAND_RESET_I(4);
    vlSelf->s_bready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->s_araddr);
    vlSelf->s_arprot = VL_RAND_RESET_I(12);
    vlSelf->s_arvalid = VL_RAND_RESET_I(4);
    vlSelf->s_arready = VL_RAND_RESET_I(4);
    VL_RAND_RESET_W(128, vlSelf->s_rdata);
    vlSelf->s_rresp = VL_RAND_RESET_I(8);
    vlSelf->s_rvalid = VL_RAND_RESET_I(4);
    vlSelf->s_rready = VL_RAND_RESET_I(4);
    vlSelf->axil_crossbar__DOT__aw_grant = VL_RAND_RESET_I(4);
    vlSelf->axil_crossbar__DOT__ar_grant = VL_RAND_RESET_I(4);
    vlSelf->axil_crossbar__DOT__aw_priority = VL_RAND_RESET_I(2);
    vlSelf->axil_crossbar__DOT__ar_priority = VL_RAND_RESET_I(2);
    vlSelf->axil_crossbar__DOT__w_owner = VL_RAND_RESET_I(8);
    vlSelf->axil_crossbar__DOT__w_owner_valid = VL_RAND_RESET_I(4);
    vlSelf->axil_crossbar__DOT__r_owner = VL_RAND_RESET_I(8);
    vlSelf->axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id = VL_RAND_RESET_I(2);
    vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m = 0;
    vlSelf->axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id = 0;
    vlSelf->axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id = 0;
    vlSelf->axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id = VL_RAND_RESET_I(2);
    vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m = 0;
    vlSelf->axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id = 0;
    vlSelf->axil_crossbar__DOT____Vlvbound_hb1c24a24__0 = VL_RAND_RESET_I(3);
    vlSelf->axil_crossbar__DOT____Vlvbound_hc5778a6f__0 = VL_RAND_RESET_I(3);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = VL_RAND_RESET_I(2);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr = VL_RAND_RESET_I(32);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = VL_RAND_RESET_I(32);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = VL_RAND_RESET_I(32);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = VL_RAND_RESET_I(2);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr = VL_RAND_RESET_I(32);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = VL_RAND_RESET_I(32);
    vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = VL_RAND_RESET_I(32);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__rst_n__0 = VL_RAND_RESET_I(1);
}
