---
title: TODO 
abbrev: TODO 
docname: draft-someone-perc-transform-00
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
  RFC5285:
  I-D.ietf-avtcore-srtp-aes-gcm:
 
informative:
  I-D.jones-perc-private-media-reqts:

--- abstract

In some conferencing scenarios, it is desirable for an intermediary to be able
to manipulate some RTP parameters, while still providing strong end-to-end
security guarantees.  This document defines an SRTP transform based on AES-GCM
that uses two separate but related cryptographic contexts to provide "hop by
hop" and "end to end" security guarantees.  This document does not define a
corresponding transform for SRTP; instead, the normal AES-GCM transforms should
be used.


--- middle

Introduction
========

Cloud conferring systems that are based on switched conferencing have a central
media distribution device (MDD) that receives media from clients and distributes
it to other clients but does not need to interpret or change the media
content. For theses systems, it is desirable to have one security association
from the sending client to the receiving client that can encrypt and
authenticated the media end to end while still allowing certain RTP header
information to be changed by the MDD. At the same time separate security
association provides integrity and optional confidentiality for the RTP and
media flowing between the MDD and the clients. More information about the can be
found in {{I-D.jones-perc-private-media-reqts}}. 

This specification uses the normal SRTP AES-GCM transform
{{I-D.ietf-avtcore-srtp-aes-gcm}} to encrypt an RTP packet to form the
end security association. The output of this is treated as an RTP packet and
again encrypted with SRTP AES GCM transform to form the hop by hop security
association between the client and the MDD. The MDD decrypts and checks
integrity of the hop by hop security. At this point the MDD may change some of
the RTP header information that would impact the end to end integrity. For any
values that are changed, the original values before changing are included in a
new RTP header extension called the Original Parameters Block. The new RTP
packet is encrypted with the hob by hop security association for the destination
client and sent. The receiving client decrypts and checks integrity for the hop
by hop association from the MDD then replaces any parameters the MDD changes
using the information in the Original Parameters Block before decrypting and
checking the end to end integrity.


Terminology
==========

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in {{!RFC2119}}.

Terms:

* MDD: media distribution device that routes media from one client to other
  clients

* E2E: end-to-end meaning the link from one client through the MDD to the client
  at the other end.

* HBH: hop-by-hop meaning the link from the client to or from the MDD.

* OPB: Original Parameters Block containing a TLVs for each value that the MDD
  changed.

Cryptographic Contexts
=================

* Same as AES-GCM, but twice; "inner" and "outer" transforms

* Generate double-length keys and salt; first half for "inner", second half for
   "outer"

* "Outer" transform: Process the packet as with normal AES-GCM transform

* "Inner" transform: Reconstruct the original RTP header / payload; process with
   AES-GCM


Original Parameters Block
==================

This is an RTP Header extension

Such an intermediary may change RTP header parameters using the process, but for
any parameters that are changed, the original values must be sent in an

Original Parameters Block prepended to the payload.

length || (type  || value) || (type || value) || ...


Operations
=======


Encrypting a Packet
----------------

Form an RTP packet

If any header extensions, MUST use {{!RFC5285}}

Apply the AES-GCM transform with the inner parameters (inner transform)

Apply the AES-GCM transform with the outer parameters (outer transform)

NB: This results in double-encryption; it might be possible to do the outer
transform integrity-only, if we're OK with the original parameters being
exposed.

This will require slightly more text.

Modifying a Packet
----------------

We assume that an intermediary has the crypto context for the outer transform,
but not the inner

Apply the (outer) AES-GCM decryption transform to the packet

Separate the OPB from the (encrypted) original payload

Change any parameters.

If a parameter you change is in the OPB already, great.

You MAY drop a parameter from the OPB if you reset it to its original value.

Can not delete any header extensions but can add them 

If add any header extensions, must append them and , must keep order of original
ones in 5285 block. The the value of the original 5285 length field needs to be
added to the OPB

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

It is obviously critical that the intermediary have only the outer transform
parameters, and not the inner.  We rely on an external key management protocol
to assure this property.

Modifications by the intermediary result in the recipient getting two values for
changed parameters (original and modified).  The recipient will have to choose
which to use; there is risk in using either that depends on the session setup.

The security properties for both the inner and outer key holders are the same as
the security properties of classic SRTP

IANA Considerations
==============

RTP Header Extension
------------------

TODO


DTLS-SRTP
---------

 We request IANA to add the following values to  defines a DTLS-SRTP "SRTP
 Protection Profile" defined in  {{!RFC5764}}.

~~~~
         DOUBLE_SRTP_AEAD_AES_128_GCM    = {TBD, TBD }
         DOUBLE_SRTP_AEAD_AES_256_GCM    = {TBD, TBD }
~~~~


The  SRTP  transform parameters for each of these protection are:
   
~~~~   
   DOUBLE_SRTP_AEAD_AES_128_GCM
        cipher:                 AES_128_GCM
        cipher_key_length:      256 bits
        cipher_salt_length:     192 bits
        aead_auth_tag_length:   32 octets
        auth_function:          NULL
        auth_key_length:        N/A
        auth_tag_length:        N/A
        maximum lifetime:       at most 2^31 SRTCP packets and
                                            at most 2^48 SRTP packets
        
   DOUBLE_SRTP_AEAD_AES_256_GCM
        cipher:                 AES_256_GCM
        cipher_key_length:      512 bits
        cipher_salt_length:     192 bits
        aead_auth_tag_length:   32 octets
        auth_function:          NULL
        auth_key_length:        N/A
        auth_tag_length:        N/A
        maximum lifetime:       at most 2^31 SRTCP packets and
                                            at most 2^48 SRTP packets
~~~~

The first half of the key and salt is used for the HBH transform and the second
half is used for the E2E transform. 

Acknowledgements
=============

Many thanks to review from TODO.


