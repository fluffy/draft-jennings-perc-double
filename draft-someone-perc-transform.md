---
title: TODO
abbrev: TODO
docname: draft-someone-perc-transform-00
date: 2015-10-16
category: std

ipr: trust200902
area: Art
workgroup: mmusic
keyword: perc

stand_alone: yes
pi: [sortrefs, symrefs]

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
security guarantees.  This document defines an SRTP and SRTCP transform based on
AES-GCM that uses two separate but related cryptographic contexts to provide
"hop by hop" and "end to end" security guarantees.


--- middle

# Introduction

Cloud conferencing systems that are based on switched conferencing have a
central media distribution device (MDD) that receives media from clients and
distributes it to other clients, but does not need to interpret or change the
media content. For theses systems, it is desirable to have one security
association from the sending client to the receiving client that can encrypt and
authenticated the media end to end while still allowing certain RTP header
information to be changed by the MDD. At the same time, a separate security
association provides integrity and optional confidentiality for the RTP and
media flowing between the MDD and the clients. More information about the can be
found in {{I-D.jones-perc-private-media-reqts}}.

This specification uses the normal SRTP AES-GCM transform
{{I-D.ietf-avtcore-srtp-aes-gcm}} to encrypt an RTP packet to form the end
security association. The output of this is treated as an RTP packet and again
encrypted with SRTP AES GCM transform to form the hop by hop security
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


# Terminology

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

# Cryptographic Contexts

This transform uses two cryptographic contexts: An "end to end" context that is
used by endpoints that originate and consume media, and a "hop by hop" context"
that is used by an MDD that wishes to make modifications to some RTP header
parameters.  The application of these transforms is described below.

The keys and salt for these contexts are generated with the following steps:

* Generate key and salt values of twice the length required by the AES-GCM
  transform

* Assign the first half of each value to be the key and salt, respectively, for
  the inner transform.

* Assign the second half of each value to be the key and salt, respectively, for
  the outer transform.

Obviously, if the MDD is to be able to modify header parameters but not decrypt
the payload, then it must have cryptographic context for the outer transform,
but not the inner transform.  This document does not define how the MDD should
be provisioned with this information.

# Original Parameters Block

Any SRTP packet processed with this transform MAY contain an Original Parameters
Block (OPB) extension.  This RTP header extension contains the original values
of any modified headers, in the following form:

~~~~~
(type  || value) || (type || value) || ...
~~~~~

In each type/value pair, the "type" field indicates the type of parameter that
was changed, and the "value" field carries the original value of the parameter.
The mapping from RTP header parameters to type values, and the length of the
value field is as follows

| Parameter  | Type | Value length |
|------------|------|--------------|
| X          | 1    | 1            |
| CC         | 2    | 1            |
| M          | 3    | 1            |
| PT         | 4    | 1            |
| Seq Num    | 5    | 2            |
| Timestamp  | 6    | 4            |
| SSRC       | 7    | 4            |
| Ext Len    | 8    | 2            |


# Operations


## Encrypting a Packet

To encrypt a packet with this transform, the endpoint encrypts the packet with
the inner transform, may add an OPB, then applies the outer transform.

* Form an RTP packet.  If there are any header extensions, they MUST use
  {{RFC5285}}.

* Apply the AES-GCM transform with the inner parameters (inner transform)

* Optionally add an OPB header extension.  The endpoint MAY include any
  parameters that are likely to be modified by the MDD, to reduce processing
  burden on the MDD.

* Apply the AES-GCM transform with the outer parameters (outer transform)


## Modifying a Packet

In order to modify a packet, the MDD undoes the outer transform, modifies the
packet, updates the OPB with any new modifications, and re-applies the outer
tranform.

* Apply the (outer) AES-GCM decryption transform to the packet

* Separate the OPB from the (encrypted) original payload

* Change any required parameters

* If a changed parameter is not already in the OPB, add it with its original
  value to the OPB. 

* If the MDD resets a parameter to its original value, it MAY drop it from the
  OPB.

* The MDD MUST NOT delete any header extensions, but MAY add them.

    * If the MDD adds any header extensions, it must append them and it must
      keep order of the original headers in 5285 block.
    
    * If the MDD appends headers, then it MUST add the the value of the original
      5285 length field to the OPB, or update it if it is already there. The
      original 5248 length is counted in words and stored in the Ext Len field
      of the OPB.

* Recombine the new OPB and the (encrypted) original payload

* Apply the (outer) AES-GCM encryption transform to the packet

## Decrypting a Packet

To decrypt a packet, the endpoint first decrypts and verifies using the outer
transform, then uses the OPB to reconstruct the original packet, which it
decrypts and verifies with the inner transform.

* Apply the (outer) AES-GCM decryption transform to the packet

* Separate the OPB from the (encrypted) original payload

* Form a new SRTP packet with:

  * Header = Received header, with params in OPB replaced with values from OPB

  * Header extensions truncated to the 5285 length in OPB

  * Payload = (encrypted) original payload

* Apply the (inner) AES-GCM decryption transform to this synthetic SRTP packet


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

TODO - Define RTP header extension for the OBP block. 


DTLS-SRTP
---------

 We request IANA to add the following values to defines a DTLS-SRTP "SRTP
 Protection Profile" defined in {{!RFC5764}}.

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

The first half of the key and salt is used for the inner (E2E) transform and the
second half is used for the outer (HBH) transform.

Acknowledgements
=============

Many thanks to review from GET YOUR NAME HERE. Send comments.




