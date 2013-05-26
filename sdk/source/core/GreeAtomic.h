//
// Copyright 2012 GREE, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <libkern/OSAtomic.h>

// Some preprocessor definitions for atomic  wrappers

#define GREE_ATOMIC_STATE_SET   1
#define GREE_ATOMIC_STATE_CLEAR 0

#define atomicIsSet(state_int)     ((state_int) == GREE_ATOMIC_STATE_SET)
#define atomicIsClear(state_int)   ((state_int) == GREE_ATOMIC_STATE_CLEAR)
#define initAtomicSet(state_int)   ((state_int) = GREE_ATOMIC_STATE_SET)
#define initAtomicClear(state_int) ((state_int) = GREE_ATOMIC_STATE_CLEAR)
#define setAtomic(state_int)       (OSAtomicCompareAndSwapIntBarrier(GREE_ATOMIC_STATE_CLEAR, GREE_ATOMIC_STATE_SET, &(state_int)))
#define clearAtomic(state_int)     (OSAtomicCompareAndSwapIntBarrier(GREE_ATOMIC_STATE_SET, GREE_ATOMIC_STATE_CLEAR, &(state_int)))
