#!/bin/sh
#---------------------------------------------------------------------
# Copyright (C) 2016-2018 Intel, Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#---------------------------------------------------------------------

product="Clear Linux* OS"
script_name=${0##*/}

check_result() {
    local ret="$1"
    local msg="$2"
    [ "$ret" -ne 0 ] && { echo "FAIL: $msg"; exit 1; }
    echo "SUCCESS: $msg"
}

have_kernel_module() {
    local module="$1"
    [ -d /sys/module/"$module" ] || modinfo "$module" >/dev/null 2>&1
}

get_cpuinfo() { # return details of the first CPU only
    cat /proc/cpuinfo | awk 'BEGIN { RS = "" ; } { printf ("%s\n", $0); exit(0); }'
}

have_cpu_feature() {
    local feature="$1"
    get_cpuinfo | egrep -q "^flags.*\<$feature\>"
}

have_efi() {
    local need="EFI firmware"
    [ -d /sys/firmware/efi ]
    check_result "$?" "$need"
}

have_kvm() {
    local module=
    for module in "kvm" "kvm_intel"; do
        have_kernel_module "$module"
        check_result "$?" "Kernel module $module"
    done
}

have_vhost() {
    local module=
    for module in "vhost" "vhost_net"; do
        have_kernel_module "$module"
        check_result "$?" "Kernel module $module"
    done
}

have_nested_kvm() {
    local file=/sys/module/kvm_intel/parameters/nested
    [ -f "$file" ] && [ $(cat "$file") = Y ]
    check_result "$?" "Nested KVM support"
}

have_kvm_unrestricted_guest () {
    local file=/sys/module/kvm_intel/parameters/unrestricted_guest
    [ -f "$file" ] && [ $(cat "$file") = Y ]
    check_result "$?" "Unrestricted guest KVM support"
}

have_vmx() {
    local feature="vmx"
    local desc="Virtualisation support"
    local need="$desc ($feature)"
    have_cpu_feature "$feature"
    check_result "$?" "$need"
}

have_ssse3_cpu_feature () {
    local feature="ssse3"
    local desc="Supplemental Streaming SIMD Extensions 3"
    local need="$desc ($feature)"
    have_cpu_feature "$feature"
    check_result "$?" "$need"
}

have_pclmul_cpu_feature () {
    local feature="pclmulqdq"
    local desc="Carry-less Multiplication extensions"
    local need="$desc ($feature)"
    have_cpu_feature "$feature"
    check_result "$?" "$need"
}

have_sse41_cpu_feature () {
    local feature="sse4_1"
    local desc="Streaming SIMD Extensions v4.1"
    local need="$desc ($feature)"
    have_cpu_feature "$feature"
    check_result "$?" "$need"
}

have_sse42_cpu_feature () {
    local feature="sse4_2"
    local desc="Streaming SIMD Extensions v4.2"
    local need="$desc ($feature)"
    have_cpu_feature "$feature"
    check_result "$?" "$need"
}

have_64bit_cpu() {
    local feature="lm" # "Long mode"
    local desc="64-bit CPU"
    local need="$desc ($feature)"
    have_cpu_feature "$feature"
    check_result "$?" "$need"
}

common_checks() {
    have_64bit_cpu && have_ssse3_cpu_feature && have_sse41_cpu_feature && \
        have_sse42_cpu_feature && have_pclmul_cpu_feature
}

check_host() {
    echo "Checking if host is capable of running $product"; echo
    common_checks
}

check_container() {
    echo "Checking if host is capable of running $product in a container"; echo
    common_checks && have_vmx && have_kvm && have_nested_kvm && have_kvm_unrestricted_guest && have_vhost
}

main() {
    case "$1" in
        container) check_container ;;
        host) check_host ;;
        *) echo "ERROR: Invalid type specified: '$1' (specify 'host' or 'container')" 2>&1; exit 1 ;;
    esac
}

main "$@" && exit 0
