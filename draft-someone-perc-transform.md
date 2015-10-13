---
title: TODO 
abbrev: TODO 
docname: draft-someone-perc-transform=00
date: 2015-10-13
category: std

ipr: trust200902
area: Art
workgroup: mmusic
keyword: perc 

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
    ins: C. TODO
    name: TODO TODO
    organization: TODO
    email: TODO@iii.ca


normative:
  RFC2119:
  RFC 5285:
 
informative:

--- abstract

In some conferencing scenarios, it is desirable for an intermediary to be able to manipulate some RTP parameters, while still providing strong end-to-end security guarantees.  This document defines an SRTP transform based on AES-GCM that uses two separate but related cryptographic contexts to provide "hop by hop" and "end to end" security guarantees.  This document does not define a corresponding transform for SRTP; instead, the normal AES-GCM transforms should be used.

--- middle


Introduction
========
TODO

Cryptographic Contexts
=================

* Same as AES-GCM, but twice; "inner" and "outer" transforms

*  Generate double-length keys and salt; first half for "inner", second half for "outer" 

* "Outer" transform: Process the packet as with normal AES-GCM transform

*  "Inner" transform: Reconstruct the original RTP header / payload; process with AES-GCM 


Original Parameters Block
==================

This is an RTP Header extension

Such an intermediary may change RTP header  parameters using the process, but for any parameters that are changed, the original values must be sent in an

Original Parameters Block prepended to the payload.

length || (type  || value) || (type || value) || ...


Operations
=======


Encrypting a Packet
----------------

Form an RTP packet

If any header extensions, MUST use 5285

Apply the AES-GCM transform with the inner parameters (inner transform)

Apply the AES-GCM transform with the outer parameters (outer transform)

NB: This results in double-encryption; it might be possible to do the outer transform integrity-only, if we're OK with the original parameters being exposed.

This will require slightly more text.

Modifying a Packet
----------------

We assume that an intermediary has the crypto context for the outer transform, but not the inner

Apply the (outer) AES-GCM decryption transform to the packet

Separate the OPB from the (encrypted) original payload

Change any parameters.

If a parameter you change is in the OPB already, great.

You MAY drop a parameter from the OPB if you reset it to its original value.

Can not delete any header extensions but can add them 

If add any header extensions, must append them and , must keep order of original ones in 5285 block. The the value of the original 5285 length field needs to be added to the OPB

If it's not in the OPB, add it

Recombine the new OPB and the (encrypted) original payload

Apply the (outer) AES-GCM encryption transform to the packet

Decrypting a Packet
-----------------

Apply the (outer) AES-GCM decryption transform to the packet

Separate the OPB from the (encrypted) original payload

Form a new SRTP packet with:

* Header = Received header, with params in OPB replaced with values from OPB

* Payload = (encrypted) original payload

* Look at original value of 5285 length in OPB to truncate header extensions

Apply the (inner) AES-GCM decryption transform to this synthetic SRTP packet

Security Considerations
================

It is obviously critical that the intermediary have only the outer transform parameters, and not the inner.  We rely on an external key management protocol to assure this property.

Modifications by the intermediary result in the recipient getting two values for changed parameters (original and modified).  The recipient will have to choose which to use; there is risk in using either that depends on the session setup.

The security properties for both the inner and outer key holders are the same as the security properties of classic SRTP

IANA Considerations
==============

TODO



Acknowledgements
=============

Many thanks to review from
