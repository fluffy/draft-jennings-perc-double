%%%
    #
    # SRTP Double Encryption Procedures
    #
    # Generation tool chain:
    #   mmark (https://github.com/miekg/mmark)
    #   xml2rfc (http://xml2rfc.ietf.org/)
    #
    Title = "SRTP Double Encryption Procedures"
    abbrev = "Double SRTP"
    category = "std"
    docName = "draft-jennings-perc-double-01"
    ipr= "trust200902"
    area = "Internet"
    keyword = ["PERC", "SRTP", "RTP", "conferencing", "encryption"]
    
    [pi]
    symrefs = "yes"
    sortrefs = "yes"

    [[author]]
    initials = "C."
    surname = "Jennings"
    fullname = "Cullen Jennings"
    organization = "Cisco Systems"
      [author.address]
      email = "fluffy@iii.ca"

    [[author]]
    initials = "P.E."
    surname = "Jones"
    fullname = "Paul E. Jones"
    organization = "Cisco Systems"
      [author.address]
      email = "paulej@packetizer.com"

    [[author]]
    initials = "A.B."
    surname = "Roach"
    fullname = "Adam Roach"
    organization = "Mozilla"
      [author.address]
      email = "adam@nostrum.com"
%%%

.# Abstract

In some conferencing scenarios, it is desirable for an intermediary to be able
to manipulate some RTP parameters, while still providing strong end-to-end
security guarantees.  This document defines SRTP procedures that use two
separate but related cryptographic contexts to provide "hop-by-hop" and
"end-to-end" security guarantees.  Both the end-to-end and hop-by-hop
cryptographic transforms can utilize an authenticated encryption with
associated data scheme or take advantage of future SRTP transforms with
different properties.  RTCP is encrypted hop-by-hop using an already-defined
SRTCP cryptographic transform.


{mainmatter}

# Introduction

Cloud conferencing systems that are based on switched conferencing have a
central media distribution device (MDD) that receives media from clients and
distributes it to other clients, but does not need to interpret or change the
media content.  For these systems, it is desirable to have one security
association from the sending client to the receiving client that can encrypt and
authenticated the media end-to-end while still allowing certain RTP header
information to be changed by the MDD.  At the same time, a separate security
association provides integrity and optional confidentiality for the RTP and
media flowing between the MDD and the clients.  See the framework document
that describes this concept in more detail in more detail in
[@I-D.jones-perc-private-media-framework].

This specification RECOMMENDS the SRTP AES-GCM transform
[@!RFC7714] to encrypt an RTP packet to form the
end-to-end security association.  The output of this is treated as an RTP packet
and (optionally) again encrypted with an SRTP transform to form the hop-by-hop
security association between the client and the MDD.  The MDD decrypts and checks
integrity of the hop-by-hop security.  The MDD MAY change some of the RTP
header information that would impact the end-to-end integrity.  For any
values that are changed, the original values before changing are included in a
new RTP header extension called the Original Header Block.  The new RTP packet is
encrypted with the hop-by-hop security association for the destination client
before being sent.  The receiving client decrypts and checks integrity for the
hop-by-hop association from the MDD then replaces any parameters the MDD changed
using the information in the Original Header Block before decrypting and
checking the end-to-end integrity.


# Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [@!RFC2119].

Terms used throughout this document include:

* MDD: media distribution device that routes media from one client to other
clients

* E2E: end-to-end, meaning the link from one client through one or more MDDs to
the client at the other end.

* HBH: hop-by-hop, meaning the link from the client to or from the MDD.

* OHB: Original Header Block is an RTP header extension that contains the
original values from the RTP header that might have been changed by an MDD.


# Cryptographic Contexts

This specification uses two cryptographic contexts: An inner ("end-to-end")
context that is used by endpoints that originate and consume media to ensure
the integrity of media end-to-end, and an outer ("hop-by-hop") context that
is used between endpoints and MDDs to ensure the integrity of media over a
single hop and to enable an MDD to modify certain RTP header fields.  The
RECOMMENDED cipher for the hop-by-hop and end-to-end context is AES-GCM.
However, other combinations of SRTP ciphers that support the procedures in
this document can be added to the IANA registry.

The keys and salt for these contexts are generated with the following steps:

* Generate key and salt values of twice the length required by the inner
  (end-to-end) and outer (hop-by-hop) transforms

* Assign the first part of each value to be the key and salt, respectively, for
  the inner (end-to-end) transform.

* Assign the second part of each value to be the key and salt, respectively, for
  the outer (hop-by-hop) transform.

As a special case, the outer cryptographic transform MAY be the NULL cipher
(see [@!RFC3711]) if a secure transport, such as [@RFC6347], is used over a
hop (i.e., between an endpoint and MDD or between two MDDs).  In that case, the
key and salt values generated would be the length required only for the inner
cryptographic transform, which MUST NOT be the NULL cipher.
  
Obviously, if the MDD is to be able to modify header fields but not decrypt the
payload, then it must have cryptographic context for the outer transform, but
not the inner transform.  This document does not define how the MDD should be
provisioned with this information.  One possible way to provide key material for
the outer ("hop-by-hop") transform is to use [@I-D.jones-perc-dtls-tunnel].


# Original Header Block

Any SRTP packet processed following these procedures MAY contain an Original
Header Block (OHB) extension.

This RTP header extension contains the original values of any modified header
fields and MUST be placed after any already-existing RTP header extensions.
Placement of the OHB after any original header extensions is important so that
the receiving endpoint can properly authenticate the original packet and
any originally included RTP header extensions, which it will do by restoring
the modified RTP header field values by copying those from the OHB and then
removing the OHB extension and any other RTP header extensions that appear
after the OHB extension.

The MDD is only permitted to modify the extension (X) bit, payload type (PT)
field, and the RTP sequence number field.

The OHB extension is either one octet in length, two octets in length, or
three octets in length.  The length of the OHB indicates what data is
contained in the extension.

If the OHB is one octet in length, it contains both the original X bit
and PT field value.  In this case, the OHB has this form:

{align="left"}
~~~~~
 0
 0 1 2 3 4 5 6 7
+---------------+
|X|     PT      |
+---------------+
~~~~~

If the OHB is two octets in length, it contains the original RTP packet
sequence number.  In this case, the OHB has this form:

{align="left"}
~~~~~
 0                   1 
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 
+-------------------------------+
|        Sequence Number        |
+-------------------------------+
~~~~~

If the OHB is three octets in length, it contains the original X bit,
PT field value, and RTP packet sequence number.  In this case, the OHB has
this form:

{align="left"}
~~~~~
 0                   1                   2
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
+---------------+-------------------------------+
|X|     PT      |        Sequence Number        |
+---------------+-------------------------------+
~~~~~

If an MDD modifies an original RTP header value, the MDD MUST include the
OHB extension to reflect the changed value(s).  If another MDD along the
media path makes additional changes to the RTP header and the original
value is not already present in the OHB, the MDD must extend the OHB by
adding the changed value to the OHB.  So as to properly preserve original
RTP header values, an MDD MUST NOT change a value already present in the
OHB extension.

# RTP Operations


## Encrypting a Packet

To encrypt a packet, the endpoint encrypts the packet with
the inner transform and then applies the outer transform.  The processes
is as follows:

* Form an RTP packet.  If there are any header extensions, they MUST use
  [@!RFC5285].

* Apply the inner cryptographic transform to the RTP packet.  If encrypting
  RTP header extensions end-to-end, then [@!RFC6904] MUST be used
  when encrypting the RTP packet using the inner transform.

* Apply the outer cryptographic transform to the RTP packet.  If encrypting
  RTP header extensions hop-by-hop, then [@!RFC6904] MUST be used
  when encrypting the RTP packet using the outer transform.


## Modifying a Packet

In order to modify a packet, the MDD undoes the outer transform, modifies the
packet, updates the OHB with any modifications not already present in the OHB,
and re-applies the outer transform.

* Apply the outer decryption transform to the packet.  If decrypting RTP
  header extensions hop-by-hop, then [@!RFC6904] MUST be used when decrypting
  the RTP packet using the outer transform.

* Change any required parameters

* If a changed RTP header field is not already in the OHB, add it with its
  original value to the OHB.  Note that in the case of cascaded MDDs, the
  first MDD may have already added an OHB.

* If the MDD resets a parameter to its original value, it MAY drop it from the
  OHB as long as there are no other header extensions following the OHB.
  Note that this might result in a decrease in the size of the OHB.

* The MDD MUST NOT delete any header extensions, but MAY add them.

    * If the MDD adds any header extensions, it must append them and it must
      maintain the order of the original headers in the [@!RFC5285] block.
    
    * If the MDD appends header extensions, then it MUST add the OHB header
      extension (if not present) and add them following the OHB.  The OHB
      serves as a demarcation point between original RTP header extensions
      introduced by the endpoint and those introduced by an MDD.  If the
      MDD did not make changes that would otherwise require an OHB, then
      it SHOULD insert an OHB that merely replicates the unchanged RTP header
      field values unchanged.
      
* The MDD MAY modify any header extension appearing after the OHB.

* Apply the outer encryption transform to the packet.  If encrypting RTP
  header extensions hop-by-hop, then [@!RFC6904] MUST be used when
  encrypting the RTP packet using the outer transform.

## Decrypting a Packet

To decrypt a packet, the endpoint first decrypts and verifies using the outer
transform, then uses the OHB to reconstruct the original packet, which it
decrypts and verifies with the inner transform.

* Apply the outer decryption transform to the packet. If the integrity check
  does not pass, discard the packet.  The result of this is referred to as the
  outer SRTP packet.  If decrypting RTP header extensions hop-by-hop, then
  [@!RFC6904] MUST be used when decrypting the RTP packet using the outer
  transform.

* Form a new synthetic SRTP packet with:

  * Header = Received header, with header fields replaced with values from
    OHB (if present).

  * Insert all header extensions up to the OHB extension, but exclude any
    that following the OHB.  If the original X bit is 1, then the remaining
    extensions MUST be padded to the first 32-bit boundary and the overall
    length of the header extensions adjusted accordingly.  If the original
    X bit is 0, then the header extensions would be removed entirely.

  * Payload is the encrypted original payload.

* Apply the inner decryption transform to this synthetic SRTP packet. If the
  integrity check does not pass, discard the packet.  If decrypting RTP
  header extensions end-to-end, then [@!RFC6904] MUST be used when decrypting
  the RTP packet using the inner transform.

Once the packet has successfully decrypted, the application needs to be careful
about which information it uses to get the correct behavior.  The application MUST
use only the information found in the synthetic SRTP packet and MUST NOT use the
other data that was in the outer SRTP packet with the following exceptions:

* The PT from the outer SRTP packet is used for normal matching to SDP and codec
  selection.

* The sequence number from the outer SRTP packet is used for normal RTP ordering.

If any of the following RTP headers extensions are found in the outer SRTP
packet, they MAY be used:

* TBD


# RTCP Operations

Unlike RTP, which is encrypted both hop-by-hop and end-to-end using two
separate cryptographic contexts, RTCP is encrypted using only the outer
(HBH) cryptographic context.  The procedures for RTCP encryption are
specified in [@!RFC3711] and this document introduces no additional steps.


# Recommended Inner and Outer Cryptographic Transforms

This specification recommends and defines AES-GCM as both the inner
and outer cryptographic transforms, identified as 
DOUBLE_AEAD_AES_128_GCM_AEAD_AES_128_GCM and
DOUBLE_AEAD_AES_256_GCM_AEAD_AES_256_GCM.  These transforms provides for
authenticated encryption and will consume additional processing time
double-encrypting for HBH and E2E.  However, the approach is secure and simple,
and is thus viewed as an acceptable trade-off in processing efficiency.

This specification also allows for the NULL cipher to be used as the outer
cryptographic transform in cases where a secure transport are used over the
hop, with those transforms identified as
DOUBLE_AEAD_AES_128_GCM_NULL_NULL and
DOUBLE_AEAD_AES_256_GCM_NULL_NULL.

If a new SRTP transform was defined that encrypted some or all of the RTP
header, it would be reasonable for systems to have the option of using that for
the outer transform.  Similarly if a new transform was defined that provided only
integrity, that would also be reasonable to use for the HBH as the payload data
is already encrypted by the E2E.


# Security Considerations

It is obviously critical that the intermediary have only the outer transform
parameters, and not the inner.  We rely on an external key management protocol
to assure this property.

Modifications by the intermediary result in the recipient getting two values for
changed parameters (original and modified).  The recipient will have to choose
which to use; there is risk in using either that depends on the session setup.

The security properties for both the inner and outer key holders are the same as
the security properties of classic SRTP.

The NULL cipher MUST be used in conjunction with an encrypted transport
for both RTP and RTCP.  Use of the NULL cipher for the outer cryptographic
context without the use of an encrypted transport exposes the RTCP traffic
to undetectable modification as it it transmitted over the network.
Likewise, RTP traffic under the same conditions would be subject to
modification that would not be detectable by the MDD.

# IANA Considerations

## RTP Header Extension

This document defines a new extension URI in the RTP Compact Header Extensions
part of the Real-Time Transport Protocol (RTP) Parameters registry,
according to the following data:

Extension URI: urn:ietf:params:rtp-hdrext:ohb

Description:   Original Header Block

Contact: Cullen Jennings <fluffy@iii.ca>

Reference:     RFCXXXX

Note to RFC Editor: Replace RFCXXXX with the RFC number of this specification. 
      

## DTLS-SRTP

We request IANA to add the following values to defines a DTLS-SRTP "SRTP
Protection Profile" defined in [@!RFC5764].

| Value        | Profile                                  | Reference |
|:-------------|:-----------------------------------------|:----------|
|  {TBD, TBD}  | DOUBLE_AEAD_AES_128_GCM_AEAD_AES_128_GCM | RFCXXXX   |
|  {TBD, TBD}  | DOUBLE_AEAD_AES_256_GCM_AEAD_AES_256_GCM | RFCXXXX   |
|  {TBD, TBD}  | DOUBLE_AEAD_AES_128_GCM_NULL_NULL        | RFCXXXX   |
|  {TBD, TBD}  | DOUBLE_AEAD_AES_256_GCM_NULL_NULL        | RFCXXXX   |

Note to IANA: Please assign value RFCXXXX and update table to point at
this RFC for these values.

The SRTP transform parameters for each of these protection are:

{align="left"}
~~~~
DOUBLE_AEAD_AES_128_GCM_AEAD_AES_128_GCM
    cipher:                 AES_128_GCM then AES_128_GCM 
    cipher_key_length:      256 bits
    cipher_salt_length:     192 bits
    aead_auth_tag_length:   32 octets
    auth_function:          NULL
    auth_key_length:        N/A
    auth_tag_length:        N/A
    maximum lifetime:       at most 2^31 SRTCP packets and
                            at most 2^48 SRTP packets

DOUBLE_AEAD_AES_256_GCM_AEAD_AES_256_GCM
    cipher:                 AES_256_GCM then AES_256_GCM 
    cipher_key_length:      512 bits
    cipher_salt_length:     192 bits
    aead_auth_tag_length:   32 octets
    auth_function:          NULL
    auth_key_length:        N/A
    auth_tag_length:        N/A
    maximum lifetime:       at most 2^31 SRTCP packets and
                            at most 2^48 SRTP packets

DOUBLE_AEAD_AES_128_GCM_NULL_NULL
    cipher:                 AES_128_GCM then identity transform
    cipher_key_length:      128 bits
    cipher_salt_length:     96 bits
    aead_auth_tag_length:   16 octets
    auth_function:          NULL
    auth_key_length:        N/A
    auth_tag_length:        N/A
    maximum lifetime:       at most 2^31 SRTCP packets and
                            at most 2^48 SRTP packets

DOUBLE_AEAD_AES_256_GCM_NULL_NULL
    cipher:                 AES_256_GCM then identity transform
    cipher_key_length:      256 bits
    cipher_salt_length:     96 bits
    aead_auth_tag_length:   16 octets
    auth_function:          NULL
    auth_key_length:        N/A
    auth_tag_length:        N/A
    maximum lifetime:       at most 2^31 SRTCP packets and
                            at most 2^48 SRTP packets
~~~~

Except then the NULL cipher is used for the outer (HBH) transform, the first
half of the key and salt is used for the inner (E2E) transform and the
second half is used for the outer (HBH) transform.  For those that use the NULL
cipher for the outer transform, the the key and salt material is applied only
to the inner transform.


# Acknowledgments

Many thanks to review from GET YOUR NAME HERE. Please, send comments.

{backmatter}
