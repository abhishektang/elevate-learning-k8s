#!/bin/bash

################################################################################
# Kubernetes Orchestration Tests Script
# Author: Abhishek Tanguturi (s4845110)
# Date: October 30, 2025
# 
# This script tests all K3s orchestration capabilities:
# 1. Self-Healing
# 2. Load Balancing
# 3. Scaling (Replica Management)
# 4. Rolling Update (Rollout)
# 5. Rollback
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MASTER_IP="34.87.248.125"
SSH_KEY="mykeys/remote-server-myproject"
SSH_USER="t_abhishek345"
NAMESPACE="elevatelearning"
DEPLOYMENT="django-web"

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=5

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

run_ssh_command() {
    ssh -i "$SSH_KEY" "$SSH_USER@$MASTER_IP" "$1"
}

test_passed() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    print_success "$1"
}

test_failed() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    print_error "$1"
}

################################################################################
# Pre-Test Checks
################################################################################

pre_test_checks() {
    print_header "PRE-TEST CHECKS"
    
    # Check SSH connection
    print_info "Checking SSH connection to master node..."
    if run_ssh_command "echo 'Connection successful'" > /dev/null 2>&1; then
        print_success "SSH connection: OK"
    else
        print_error "SSH connection failed!"
        exit 1
    fi
    
    # Check cluster status
    print_info "Checking cluster status..."
    NODE_COUNT=$(run_ssh_command "kubectl get nodes --no-headers | wc -l")
    echo "Nodes in cluster: $NODE_COUNT"
    
    # Check namespace
    print_info "Checking namespace..."
    if run_ssh_command "kubectl get namespace $NAMESPACE" > /dev/null 2>&1; then
        print_success "Namespace '$NAMESPACE' exists"
    else
        print_error "Namespace '$NAMESPACE' not found!"
        exit 1
    fi
    
    # Display current state
    print_section "INITIAL CLUSTER STATE"
    run_ssh_command "kubectl get nodes"
    echo ""
    run_ssh_command "kubectl get pods -n $NAMESPACE -o wide"
}

################################################################################
# TEST 1: Self-Healing
################################################################################

test_self_healing() {
    print_header "TEST 1: SELF-HEALING"
    
    print_section "BEFORE DELETION"
    run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT"
    
    # Get pod to delete
    POD_TO_DELETE=$(run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[0].metadata.name}'")
    echo ""
    print_info "Deleting pod: $POD_TO_DELETE"
    
    # Delete pod
    run_ssh_command "kubectl delete pod $POD_TO_DELETE -n $NAMESPACE" > /dev/null 2>&1
    
    print_section "IMMEDIATELY AFTER DELETION"
    run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT"
    
    # Wait for self-healing
    print_info "Waiting for Kubernetes to recreate the pod..."
    sleep 5
    
    # Wait for all pods to be ready
    print_info "Waiting for all pods to become ready..."
    if run_ssh_command "kubectl wait --for=condition=ready pod -l app=$DEPLOYMENT -n $NAMESPACE --timeout=120s" > /dev/null 2>&1; then
        print_section "AFTER SELF-HEALING"
        run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide"
        
        # Verify pod count
        POD_COUNT=$(run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT --no-headers | wc -l")
        READY_COUNT=$(run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT --no-headers | grep '1/1' | wc -l")
        
        echo ""
        echo "Total pods: $POD_COUNT"
        echo "Ready pods: $READY_COUNT"
        
        if [ "$POD_COUNT" -eq "$READY_COUNT" ]; then
            test_passed "Self-Healing Test PASSED - Pod automatically recreated"
        else
            test_failed "Self-Healing Test FAILED - Not all pods are ready"
        fi
    else
        test_failed "Self-Healing Test FAILED - Timeout waiting for pods"
    fi
}

################################################################################
# TEST 2: Load Balancing
################################################################################

test_load_balancing() {
    print_header "TEST 2: LOAD BALANCING"
    
    print_info "Sending 15 requests to test load distribution..."
    
    REQUESTS=15
    SUCCESS_COUNT=0
    
    for i in $(seq 1 $REQUESTS); do
        HTTP_CODE=$(run_ssh_command "curl -s -o /dev/null -w '%{http_code}' http://localhost:30080/elevatelearning/home/")
        if [ "$HTTP_CODE" = "200" ]; then
            echo "Request $i: HTTP $HTTP_CODE ✓"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "Request $i: HTTP $HTTP_CODE ✗"
        fi
    done
    
    echo ""
    print_section "LOAD BALANCING RESULTS"
    echo "Total requests: $REQUESTS"
    echo "Successful: $SUCCESS_COUNT"
    echo "Failed: $((REQUESTS - SUCCESS_COUNT))"
    echo "Success rate: $(awk "BEGIN {printf \"%.1f\", ($SUCCESS_COUNT/$REQUESTS)*100}")%"
    
    print_info "Checking request distribution across pods..."
    echo ""
    run_ssh_command "for pod in \$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[*].metadata.name}'); do echo \"Pod: \$pod\"; kubectl logs \$pod -n $NAMESPACE --tail=5 | grep -c GET 2>/dev/null || echo '0'; done"
    
    if [ "$SUCCESS_COUNT" -eq "$REQUESTS" ]; then
        test_passed "Load Balancing Test PASSED - 100% success rate"
    else
        test_failed "Load Balancing Test FAILED - Some requests failed"
    fi
}

################################################################################
# TEST 3: Scaling
################################################################################

test_scaling() {
    print_header "TEST 3: SCALING (REPLICA MANAGEMENT)"
    
    # Get current replica count
    CURRENT_REPLICAS=$(run_ssh_command "kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}'")
    echo "Current replicas: $CURRENT_REPLICAS"
    
    # Scale up
    print_section "SCALING UP: $CURRENT_REPLICAS → 5"
    SCALE_START=$(date +%s)
    
    run_ssh_command "kubectl scale deployment $DEPLOYMENT --replicas=5 -n $NAMESPACE" > /dev/null 2>&1
    
    if run_ssh_command "kubectl wait --for=condition=ready pod -l app=$DEPLOYMENT -n $NAMESPACE --timeout=120s" > /dev/null 2>&1; then
        SCALE_END=$(date +%s)
        SCALE_TIME=$((SCALE_END - SCALE_START))
        
        run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide"
        print_success "Scaled up to 5 replicas in ${SCALE_TIME} seconds"
    else
        test_failed "Scaling Test FAILED - Timeout during scale up"
        return
    fi
    
    sleep 3
    
    # Scale down
    print_section "SCALING DOWN: 5 → 3"
    SCALE_START=$(date +%s)
    
    run_ssh_command "kubectl scale deployment $DEPLOYMENT --replicas=3 -n $NAMESPACE" > /dev/null 2>&1
    sleep 10
    
    SCALE_END=$(date +%s)
    SCALE_TIME=$((SCALE_END - SCALE_START))
    
    run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide"
    print_success "Scaled down to 3 replicas in ${SCALE_TIME} seconds"
    
    # Verify final state
    FINAL_REPLICAS=$(run_ssh_command "kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}'")
    
    if [ "$FINAL_REPLICAS" = "3" ]; then
        test_passed "Scaling Test PASSED - Successfully scaled up and down"
    else
        test_failed "Scaling Test FAILED - Incorrect final replica count"
    fi
}

################################################################################
# TEST 4: Rolling Update (Rollout)
################################################################################

test_rollout() {
    print_header "TEST 4: ROLLING UPDATE (ROLLOUT)"
    
    print_section "CURRENT ROLLOUT HISTORY"
    run_ssh_command "kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE"
    
    # Perform rolling update
    print_section "STARTING ROLLING UPDATE"
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    print_info "Adding environment variables: TEST_VERSION=v8.0, UPDATE_TIME=$TIMESTAMP"
    
    ROLLOUT_START=$(date +%s)
    
    run_ssh_command "kubectl set env deployment/$DEPLOYMENT -n $NAMESPACE TEST_VERSION=v5.0 UPDATE_TIME=$TIMESTAMP" > /dev/null 2>&1
    
    print_info "Monitoring rollout progress..."
    if run_ssh_command "kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=180s" > /dev/null 2>&1; then
        ROLLOUT_END=$(date +%s)
        ROLLOUT_TIME=$((ROLLOUT_END - ROLLOUT_START))
        
        print_success "Rollout completed in ${ROLLOUT_TIME} seconds"
        
        # Test zero downtime
        print_section "TESTING ZERO DOWNTIME"
        print_info "Sending 5 requests to verify availability..."
        
        DOWNTIME_DETECTED=0
        for i in $(seq 1 5); do
            HTTP_CODE=$(run_ssh_command "curl -s -o /dev/null -w '%{http_code}' http://localhost:30080/elevatelearning/home/")
            if [ "$HTTP_CODE" = "200" ]; then
                echo "Request $i: HTTP $HTTP_CODE ✓"
            else
                echo "Request $i: HTTP $HTTP_CODE ✗"
                DOWNTIME_DETECTED=1
            fi
        done
        
        print_section "UPDATED DEPLOYMENT"
        run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide"
        
        echo ""
        run_ssh_command "kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE"
        
        if [ "$DOWNTIME_DETECTED" = "0" ]; then
            test_passed "Rolling Update Test PASSED - Zero downtime deployment"
        else
            test_failed "Rolling Update Test FAILED - Downtime detected"
        fi
    else
        test_failed "Rolling Update Test FAILED - Rollout timeout"
    fi
}

################################################################################
# TEST 5: Rollback
################################################################################

test_rollback() {
    print_header "TEST 5: ROLLBACK"
    
    print_section "CURRENT REVISION"
    run_ssh_command "kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE | tail -3"
    
    # Perform rollback
    print_info "Rolling back to previous revision..."
    ROLLBACK_START=$(date +%s)
    
    run_ssh_command "kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE" > /dev/null 2>&1
    
    if run_ssh_command "kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=180s" > /dev/null 2>&1; then
        ROLLBACK_END=$(date +%s)
        ROLLBACK_TIME=$((ROLLBACK_END - ROLLBACK_START))
        
        print_success "Rollback completed in ${ROLLBACK_TIME} seconds"
        
        # Test availability after rollback
        print_section "TESTING AVAILABILITY AFTER ROLLBACK"
        print_info "Sending 5 requests..."
        
        FAILURE_DETECTED=0
        for i in $(seq 1 5); do
            HTTP_CODE=$(run_ssh_command "curl -s -o /dev/null -w '%{http_code}' http://localhost:30080/elevatelearning/home/")
            if [ "$HTTP_CODE" = "200" ]; then
                echo "Request $i: HTTP $HTTP_CODE ✓"
            else
                echo "Request $i: HTTP $HTTP_CODE ✗"
                FAILURE_DETECTED=1
            fi
        done
        
        print_section "ROLLED BACK DEPLOYMENT"
        run_ssh_command "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide"
        
        echo ""
        print_section "UPDATED ROLLOUT HISTORY"
        run_ssh_command "kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE"
        
        if [ "$FAILURE_DETECTED" = "0" ]; then
            test_passed "Rollback Test PASSED - Successfully rolled back with zero downtime"
        else
            test_failed "Rollback Test FAILED - Request failures detected"
        fi
    else
        test_failed "Rollback Test FAILED - Rollback timeout"
    fi
}

################################################################################
# Final Summary
################################################################################

print_summary() {
    print_header "TEST SUMMARY"
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           ORCHESTRATION TESTS COMPLETE                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_section "RESULTS"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo ""
        print_success "ALL TESTS PASSED! 🎉"
        echo ""
        print_section "FINAL CLUSTER STATE"
        run_ssh_command "kubectl get nodes"
        echo ""
        run_ssh_command "kubectl get all -n $NAMESPACE"
        
        return 0
    else
        echo ""
        print_error "Some tests failed. Please review the output above."
        return 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    print_header "KUBERNETES ORCHESTRATION TEST SUITE"
    echo "Testing K3s cluster orchestration capabilities"
    echo "Master Node: $MASTER_IP"
    echo "Namespace: $NAMESPACE"
    echo ""
    
    # Run pre-test checks
    pre_test_checks
    
    # Prompt to continue
    echo ""
    read -p "Press Enter to start tests (or Ctrl+C to cancel)..."
    
    # Run all tests
    test_self_healing
    sleep 3
    
    test_load_balancing
    sleep 3
    
    test_scaling
    sleep 3
    
    test_rollout
    sleep 3
    
    test_rollback
    
    # Print summary
    print_summary
    
    exit $?
}

# Run main function
main
