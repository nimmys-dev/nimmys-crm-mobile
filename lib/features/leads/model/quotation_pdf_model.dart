// quotation_pdf_response.dart

/// Root response wrapper for the quotation PDF generation API.
class QuotationPdfResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final QuotationPdfData? data;

  QuotationPdfResponse({
    this.status,
    this.statusCode,
    this.message,
    this.data,
  });

  factory QuotationPdfResponse.fromJson(Map<String, dynamic> json) {
    return QuotationPdfResponse(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? QuotationPdfData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

/// The nested data object containing lead, quotation, company, and PDF URL.
class QuotationPdfData {
  final Lead? lead;
  final Quotation? quotation;
  final Company? company;
  final String? pdfUrl;

  QuotationPdfData({
    this.lead,
    this.quotation,
    this.company,
    this.pdfUrl,
  });

  factory QuotationPdfData.fromJson(Map<String, dynamic> json) {
    return QuotationPdfData(
      lead: json['lead'] != null
          ? Lead.fromJson(json['lead'] as Map<String, dynamic>)
          : null,
      quotation: json['quotation'] != null
          ? Quotation.fromJson(json['quotation'] as Map<String, dynamic>)
          : null,
      company: json['company'] != null
          ? Company.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      pdfUrl: json['pdf_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lead': lead?.toJson(),
      'quotation': quotation?.toJson(),
      'company': company?.toJson(),
      'pdf_url': pdfUrl,
    };
  }
}

/// Lead information from the quotation.
class Lead {
  final int? id;
  final String? reference;
  final String? name;
  final String? phone;
  final String? source;
  final String? assignedTo;
  final String? description;

  Lead({
    this.id,
    this.reference,
    this.name,
    this.phone,
    this.source,
    this.assignedTo,
    this.description,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as int?,
      reference: json['reference'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      source: json['source'] as String?,
      assignedTo: json['assigned_to'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'name': name,
      'phone': phone,
      'source': source,
      'assigned_to': assignedTo,
      'description': description,
    };
  }
}

/// Quotation details including items and financials.
class Quotation {
  final int? id;
  final String? reference;
  final String? customerName;
  final String? customerAddress;
  final String? issueDate;          // ISO date string – keep as String
  final String? terms;
  final String? subtotal;           // stored as string in JSON
  final String? discountPercent;
  final String? taxPercent;
  final String? total;
  final List<QuotationItem>? items;

  Quotation({
    this.id,
    this.reference,
    this.customerName,
    this.customerAddress,
    this.issueDate,
    this.terms,
    this.subtotal,
    this.discountPercent,
    this.taxPercent,
    this.total,
    this.items,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['items'] as List?;
    List<QuotationItem>? itemList = itemsJson?.map((e) =>
        QuotationItem.fromJson(e as Map<String, dynamic>)).toList();

    return Quotation(
      id: json['id'] as int?,
      reference: json['reference'] as String?,
      customerName: json['customer_name'] as String?,
      customerAddress: json['customer_address'] as String?,
      issueDate: json['issue_date'] as String?,
      terms: json['terms'] as String?,
      subtotal: json['subtotal'] as String?,
      discountPercent: json['discount_percent'] as String?,
      taxPercent: json['tax_percent'] as String?,
      total: json['total'] as String?,
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'issue_date': issueDate,
      'terms': terms,
      'subtotal': subtotal,
      'discount_percent': discountPercent,
      'tax_percent': taxPercent,
      'total': total,
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }
}

/// A single line item inside the quotation.
class QuotationItem {
  final int? id;
  final String? description;
  final String? quantity;
  final String? rate;
  final String? basicRate;
  final String? taxPercent;
  final String? taxAmount;
  final String? amount;
  final int? sortOrder;

  QuotationItem({
    this.id,
    this.description,
    this.quantity,
    this.rate,
    this.basicRate,
    this.taxPercent,
    this.taxAmount,
    this.amount,
    this.sortOrder,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['id'] as int?,
      description: json['description'] as String?,
      quantity: json['quantity'] as String?,
      rate: json['rate'] as String?,
      basicRate: json['basic_rate'] as String?,
      taxPercent: json['tax_percent'] as String?,
      taxAmount: json['tax_amount'] as String?,
      amount: json['amount'] as String?,
      sortOrder: json['sort_order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'basic_rate': basicRate,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'amount': amount,
      'sort_order': sortOrder,
    };
  }
}

/// Company details (the store/outlet issuing the quotation).
class Company {
  final int? id;
  final String? name;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? email;
  final String? logo;

  Company({
    this.id,
    this.name,
    this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phone,
    this.email,
    this.logo,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int?,
      name: json['name'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logo: json['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'email': email,
      'logo': logo,
    };
  }
}