// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxil_crossbar.h for the primary calling header

#include "Vaxil_crossbar__pch.h"
#include "Vaxil_crossbar___024root.h"

VL_INLINE_OPT void Vaxil_crossbar___024root___ico_sequent__TOP__0(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___ico_sequent__TOP__0\n"); );
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

void Vaxil_crossbar___024root___eval_ico(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_ico\n"); );
    // Body
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        Vaxil_crossbar___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void Vaxil_crossbar___024root___eval_triggers__ico(Vaxil_crossbar___024root* vlSelf);

bool Vaxil_crossbar___024root___eval_phase__ico(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_phase__ico\n"); );
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vaxil_crossbar___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelf->__VicoTriggered.any();
    if (__VicoExecute) {
        Vaxil_crossbar___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vaxil_crossbar___024root___eval_act(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vaxil_crossbar___024root___nba_sequent__TOP__0(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*3:0*/ axil_crossbar__DOT__aw_request;
    axil_crossbar__DOT__aw_request = 0;
    CData/*3:0*/ axil_crossbar__DOT__ar_request;
    axil_crossbar__DOT__ar_request = 0;
    CData/*3:0*/ axil_crossbar__DOT__r_owner_valid;
    axil_crossbar__DOT__r_owner_valid = 0;
    IData/*31:0*/ axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx;
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk3__DOT__unnamedblk4__DOT__idx = 0;
    IData/*31:0*/ axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx;
    axil_crossbar__DOT__g_round_robin__DOT__unnamedblk5__DOT__unnamedblk6__DOT__idx = 0;
    CData/*1:0*/ __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout;
    __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__1__addr;
    __Vfunc_axil_crossbar__DOT__decode_address__1__addr = 0;
    IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base;
    __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0;
    IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask;
    __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0;
    CData/*1:0*/ __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout;
    __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__3__addr;
    __Vfunc_axil_crossbar__DOT__decode_address__3__addr = 0;
    IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base;
    __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0;
    IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask;
    __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0;
    CData/*1:0*/ __Vdly__axil_crossbar__DOT__aw_priority;
    __Vdly__axil_crossbar__DOT__aw_priority = 0;
    CData/*1:0*/ __Vdly__axil_crossbar__DOT__ar_priority;
    __Vdly__axil_crossbar__DOT__ar_priority = 0;
    // Body
    __Vdly__axil_crossbar__DOT__ar_priority = vlSelf->axil_crossbar__DOT__ar_priority;
    __Vdly__axil_crossbar__DOT__aw_priority = vlSelf->axil_crossbar__DOT__aw_priority;
    if (vlSelf->rst_n) {
        if ((0U != (IData)(vlSelf->axil_crossbar__DOT__ar_grant))) {
            __Vdly__axil_crossbar__DOT__ar_priority 
                = (3U & ((IData)(1U) + (IData)(vlSelf->axil_crossbar__DOT__ar_priority)));
            if ((3U <= (IData)(vlSelf->axil_crossbar__DOT__ar_priority))) {
                __Vdly__axil_crossbar__DOT__ar_priority = 0U;
            }
        }
        if ((0U != (IData)(vlSelf->axil_crossbar__DOT__aw_grant))) {
            __Vdly__axil_crossbar__DOT__aw_priority 
                = (3U & ((IData)(1U) + (IData)(vlSelf->axil_crossbar__DOT__aw_priority)));
            if ((3U <= (IData)(vlSelf->axil_crossbar__DOT__aw_priority))) {
                __Vdly__axil_crossbar__DOT__aw_priority = 0U;
            }
        }
    } else {
        __Vdly__axil_crossbar__DOT__ar_priority = 0U;
        __Vdly__axil_crossbar__DOT__aw_priority = 0U;
    }
    if (vlSelf->rst_n) {
        if ((1U & ((IData)(vlSelf->s_arvalid) & (IData)(vlSelf->s_arready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) 
                         & (0U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_araddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))))) 
                                               | (vlSelf->m_araddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                                goto __Vlabel10;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 1U;
                                                goto __Vlabel10;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 2U;
                                                goto __Vlabel10;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 3U;
                                                goto __Vlabel10;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                            __Vlabel10: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__r_owner 
                            = ((0xfcU & (IData)(vlSelf->axil_crossbar__DOT__r_owner)) 
                               | (3U & vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m));
                        axil_crossbar__DOT__r_owner_valid 
                            = (1U | (IData)(axil_crossbar__DOT__r_owner_valid));
                        goto __Vlabel9;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m);
                }
                __Vlabel9: ;
            }
        } else if ((1U & ((IData)(vlSelf->s_rvalid) 
                          & (IData)(vlSelf->s_rready)))) {
            axil_crossbar__DOT__r_owner_valid = (0xeU 
                                                 & (IData)(axil_crossbar__DOT__r_owner_valid));
        }
        if ((2U & ((IData)(vlSelf->s_arvalid) & (IData)(vlSelf->s_arready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) 
                         & (1U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_araddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))))) 
                                               | (vlSelf->m_araddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                                goto __Vlabel12;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 1U;
                                                goto __Vlabel12;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 2U;
                                                goto __Vlabel12;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 3U;
                                                goto __Vlabel12;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                            __Vlabel12: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__r_owner 
                            = ((0xf3U & (IData)(vlSelf->axil_crossbar__DOT__r_owner)) 
                               | (0xcU & (vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                                          << 2U)));
                        axil_crossbar__DOT__r_owner_valid 
                            = (2U | (IData)(axil_crossbar__DOT__r_owner_valid));
                        goto __Vlabel11;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m);
                }
                __Vlabel11: ;
            }
        } else if ((2U & ((IData)(vlSelf->s_rvalid) 
                          & (IData)(vlSelf->s_rready)))) {
            axil_crossbar__DOT__r_owner_valid = (0xdU 
                                                 & (IData)(axil_crossbar__DOT__r_owner_valid));
        }
        if ((4U & ((IData)(vlSelf->s_arvalid) & (IData)(vlSelf->s_arready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) 
                         & (2U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_araddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))))) 
                                               | (vlSelf->m_araddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                                goto __Vlabel14;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 1U;
                                                goto __Vlabel14;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 2U;
                                                goto __Vlabel14;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 3U;
                                                goto __Vlabel14;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                            __Vlabel14: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__r_owner 
                            = ((0xcfU & (IData)(vlSelf->axil_crossbar__DOT__r_owner)) 
                               | (0x30U & (vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                                           << 4U)));
                        axil_crossbar__DOT__r_owner_valid 
                            = (4U | (IData)(axil_crossbar__DOT__r_owner_valid));
                        goto __Vlabel13;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m);
                }
                __Vlabel13: ;
            }
        } else if ((4U & ((IData)(vlSelf->s_rvalid) 
                          & (IData)(vlSelf->s_rready)))) {
            axil_crossbar__DOT__r_owner_valid = (0xbU 
                                                 & (IData)(axil_crossbar__DOT__r_owner_valid));
        }
        if ((8U & ((IData)(vlSelf->s_arvalid) & (IData)(vlSelf->s_arready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__ar_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m)) 
                         & (3U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_araddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))))) 
                                               | (vlSelf->m_araddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                                goto __Vlabel16;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 1U;
                                                goto __Vlabel16;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 2U;
                                                goto __Vlabel16;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__3__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__3__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 3U;
                                                goto __Vlabel16;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout = 0U;
                                            __Vlabel16: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__3__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__r_owner 
                            = ((0x3fU & (IData)(vlSelf->axil_crossbar__DOT__r_owner)) 
                               | (0xc0U & (vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                                           << 6U)));
                        axil_crossbar__DOT__r_owner_valid 
                            = (8U | (IData)(axil_crossbar__DOT__r_owner_valid));
                        goto __Vlabel15;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m);
                }
                __Vlabel15: ;
            }
        } else if ((8U & ((IData)(vlSelf->s_rvalid) 
                          & (IData)(vlSelf->s_rready)))) {
            axil_crossbar__DOT__r_owner_valid = (7U 
                                                 & (IData)(axil_crossbar__DOT__r_owner_valid));
        }
    } else {
        vlSelf->axil_crossbar__DOT__r_owner = 0U;
        axil_crossbar__DOT__r_owner_valid = 0U;
    }
    if (vlSelf->rst_n) {
        if ((1U & ((IData)(vlSelf->s_awvalid) & (IData)(vlSelf->s_awready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) 
                         & (0U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_awaddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))))) 
                                               | (vlSelf->m_awaddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                                goto __Vlabel18;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 1U;
                                                goto __Vlabel18;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 2U;
                                                goto __Vlabel18;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 3U;
                                                goto __Vlabel18;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                            __Vlabel18: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__w_owner 
                            = ((0xfcU & (IData)(vlSelf->axil_crossbar__DOT__w_owner)) 
                               | (3U & vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m));
                        vlSelf->axil_crossbar__DOT__w_owner_valid 
                            = (1U | (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
                        goto __Vlabel17;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m);
                }
                __Vlabel17: ;
            }
        } else if ((1U & ((IData)(vlSelf->s_wvalid) 
                          & (IData)(vlSelf->s_wready)))) {
            vlSelf->axil_crossbar__DOT__w_owner_valid 
                = (0xeU & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
        }
        if ((2U & ((IData)(vlSelf->s_awvalid) & (IData)(vlSelf->s_awready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) 
                         & (1U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_awaddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))))) 
                                               | (vlSelf->m_awaddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                                goto __Vlabel20;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 1U;
                                                goto __Vlabel20;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 2U;
                                                goto __Vlabel20;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 3U;
                                                goto __Vlabel20;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                            __Vlabel20: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__w_owner 
                            = ((0xf3U & (IData)(vlSelf->axil_crossbar__DOT__w_owner)) 
                               | (0xcU & (vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                                          << 2U)));
                        vlSelf->axil_crossbar__DOT__w_owner_valid 
                            = (2U | (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
                        goto __Vlabel19;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m);
                }
                __Vlabel19: ;
            }
        } else if ((2U & ((IData)(vlSelf->s_wvalid) 
                          & (IData)(vlSelf->s_wready)))) {
            vlSelf->axil_crossbar__DOT__w_owner_valid 
                = (0xdU & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
        }
        if ((4U & ((IData)(vlSelf->s_awvalid) & (IData)(vlSelf->s_awready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) 
                         & (2U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_awaddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))))) 
                                               | (vlSelf->m_awaddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                                goto __Vlabel22;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 1U;
                                                goto __Vlabel22;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 2U;
                                                goto __Vlabel22;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 3U;
                                                goto __Vlabel22;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                            __Vlabel22: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__w_owner 
                            = ((0xcfU & (IData)(vlSelf->axil_crossbar__DOT__w_owner)) 
                               | (0x30U & (vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                                           << 4U)));
                        vlSelf->axil_crossbar__DOT__w_owner_valid 
                            = (4U | (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
                        goto __Vlabel21;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m);
                }
                __Vlabel21: ;
            }
        } else if ((4U & ((IData)(vlSelf->s_wvalid) 
                          & (IData)(vlSelf->s_wready)))) {
            vlSelf->axil_crossbar__DOT__w_owner_valid 
                = (0xbU & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
        }
        if ((8U & ((IData)(vlSelf->s_awvalid) & (IData)(vlSelf->s_awready)))) {
            vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m = 0U;
            {
                while (VL_GTS_III(32, 4U, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) {
                    if ((((IData)(vlSelf->axil_crossbar__DOT__aw_grant) 
                          >> (3U & vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m)) 
                         & (3U == ([&]() {
                                        __Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                            = (((0U 
                                                 == 
                                                 (0x1fU 
                                                  & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U)))
                                                 ? 0U
                                                 : 
                                                (vlSelf->m_awaddr[
                                                 (((IData)(0x1fU) 
                                                   + 
                                                   (0x7fU 
                                                    & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))) 
                                                  >> 5U)] 
                                                 << 
                                                 ((IData)(0x20U) 
                                                  - 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))))) 
                                               | (vlSelf->m_awaddr[
                                                  (3U 
                                                   & (VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U) 
                                                      >> 5U))] 
                                                  >> 
                                                  (0x1fU 
                                                   & VL_SHIFTL_III(7,32,32, vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m, 5U))));
                                        {
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                                goto __Vlabel24;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 1U;
                                                goto __Vlabel24;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 2U;
                                                goto __Vlabel24;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
                                            if (((__Vfunc_axil_crossbar__DOT__decode_address__1__addr 
                                                  & __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                                                 == __Vfunc_axil_crossbar__DOT__decode_address__1__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                                                __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 3U;
                                                goto __Vlabel24;
                                            }
                                            __Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout = 0U;
                                            __Vlabel24: ;
                                        }
                                    }(), (IData)(__Vfunc_axil_crossbar__DOT__decode_address__1__Vfuncout))))) {
                        vlSelf->axil_crossbar__DOT__w_owner 
                            = ((0x3fU & (IData)(vlSelf->axil_crossbar__DOT__w_owner)) 
                               | (0xc0U & (vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                                           << 6U)));
                        vlSelf->axil_crossbar__DOT__w_owner_valid 
                            = (8U | (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
                        goto __Vlabel23;
                    }
                    vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m 
                        = ((IData)(1U) + vlSelf->axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m);
                }
                __Vlabel23: ;
            }
        } else if ((8U & ((IData)(vlSelf->s_wvalid) 
                          & (IData)(vlSelf->s_wready)))) {
            vlSelf->axil_crossbar__DOT__w_owner_valid 
                = (7U & (IData)(vlSelf->axil_crossbar__DOT__w_owner_valid));
        }
    } else {
        vlSelf->axil_crossbar__DOT__w_owner = 0U;
        vlSelf->axil_crossbar__DOT__w_owner_valid = 0U;
    }
    vlSelf->axil_crossbar__DOT__ar_priority = __Vdly__axil_crossbar__DOT__ar_priority;
    vlSelf->axil_crossbar__DOT__aw_priority = __Vdly__axil_crossbar__DOT__aw_priority;
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
                goto __Vlabel25;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel25;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel25;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel25;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel25: ;
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
                goto __Vlabel26;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel26;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel26;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel26;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel26: ;
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
                goto __Vlabel27;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel27;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel27;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel27;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel27: ;
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
                goto __Vlabel28;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 1U;
                goto __Vlabel28;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 2U;
                goto __Vlabel28;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 3U;
                goto __Vlabel28;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout = 0U;
            __Vlabel28: ;
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
                goto __Vlabel29;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel29;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel29;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel29;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel29: ;
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
                goto __Vlabel30;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel30;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel30;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel30;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel30: ;
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
                goto __Vlabel31;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel31;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel31;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel31;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel31: ;
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
                goto __Vlabel32;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 1U;
                goto __Vlabel32;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 2U;
                goto __Vlabel32;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base = 0U;
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask = 0U;
            if (((vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__addr 
                  & vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask) 
                 == vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base)) {
                vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 3U;
                goto __Vlabel32;
            }
            vlSelf->__Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout = 0U;
            __Vlabel32: ;
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
}

void Vaxil_crossbar___024root___eval_nba(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vaxil_crossbar___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vaxil_crossbar___024root___eval_triggers__act(Vaxil_crossbar___024root* vlSelf);

bool Vaxil_crossbar___024root___eval_phase__act(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vaxil_crossbar___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vaxil_crossbar___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vaxil_crossbar___024root___eval_phase__nba(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vaxil_crossbar___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__ico(Vaxil_crossbar___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__nba(Vaxil_crossbar___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxil_crossbar___024root___dump_triggers__act(Vaxil_crossbar___024root* vlSelf);
#endif  // VL_DEBUG

void Vaxil_crossbar___024root___eval(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelf->__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY((0x64U < __VicoIterCount))) {
#ifdef VL_DEBUG
            Vaxil_crossbar___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../rtl/axil_crossbar.sv", 9, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vaxil_crossbar___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelf->__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vaxil_crossbar___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../rtl/axil_crossbar.sv", 9, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vaxil_crossbar___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../rtl/axil_crossbar.sv", 9, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vaxil_crossbar___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vaxil_crossbar___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vaxil_crossbar___024root___eval_debug_assertions(Vaxil_crossbar___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vaxil_crossbar__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxil_crossbar___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst_n & 0xfeU))) {
        Verilated::overWidthError("rst_n");}
    if (VL_UNLIKELY((vlSelf->m_awvalid & 0xf0U))) {
        Verilated::overWidthError("m_awvalid");}
    if (VL_UNLIKELY((vlSelf->m_wvalid & 0xf0U))) {
        Verilated::overWidthError("m_wvalid");}
    if (VL_UNLIKELY((vlSelf->m_bready & 0xf0U))) {
        Verilated::overWidthError("m_bready");}
    if (VL_UNLIKELY((vlSelf->m_arvalid & 0xf0U))) {
        Verilated::overWidthError("m_arvalid");}
    if (VL_UNLIKELY((vlSelf->m_rready & 0xf0U))) {
        Verilated::overWidthError("m_rready");}
    if (VL_UNLIKELY((vlSelf->s_awready & 0xf0U))) {
        Verilated::overWidthError("s_awready");}
    if (VL_UNLIKELY((vlSelf->s_wready & 0xf0U))) {
        Verilated::overWidthError("s_wready");}
    if (VL_UNLIKELY((vlSelf->s_bvalid & 0xf0U))) {
        Verilated::overWidthError("s_bvalid");}
    if (VL_UNLIKELY((vlSelf->s_arready & 0xf0U))) {
        Verilated::overWidthError("s_arready");}
    if (VL_UNLIKELY((vlSelf->s_rvalid & 0xf0U))) {
        Verilated::overWidthError("s_rvalid");}
}
#endif  // VL_DEBUG
