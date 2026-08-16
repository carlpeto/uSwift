/*

uRuntime - simplified runtime for microcontrollers

copyright (c) Carl Peto 2017-2019
all rights reserved

Derived work from swift stdlib according to license.

*/


SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
MetadataResponse swift_getAssociatedTypeWitness(
                                          MetadataRequest request,
                                          WitnessTable *wtable,
                                          const Metadata *conformingType,
                                          const ProtocolRequirement *reqBase,
                                          const ProtocolRequirement *assocType);