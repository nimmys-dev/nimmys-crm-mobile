// /// Response for updating a lead and its quotation.
// class LeadUpdateResponse {
//   final bool? status;
//   final int? statusCode;
//   final String? message;
//   final LeadUpdateData? data;

//   LeadUpdateResponse({
//     this.status,
//     this.statusCode,
//     this.message,
//     this.data,
//   });

//   factory LeadUpdateResponse.fromJson(Map<String, dynamic> json) {
//     return LeadUpdateResponse(
//       status: json["status"] as bool?,
//       statusCode: json["status_code"] as int?,
//       message: json["message"] as String?,
//       data: json["data"] == null
//           ? null
//           : LeadUpdateData.fromJson(json["data"] as Map<String, dynamic>),
//     );
//   }

//   Map<String, dynamic> toJson() => <String, dynamic>{
//         "status": status,
//         "status_code": statusCode,
//         "message": message,
//         if (data != null) "data": data!.toJson(),
//       };
// }

// /// Data wrapper containing lead and quotation.
// class LeadUpdateData {
//   final LeadUpdateLead? lead;
//   final LeadUpdateQuotation? quotation;

//   LeadUpdateData({
//     this.lead,
//     this.quotation,
//   });

//   factory LeadUpdateData.fromJson(Map<String, dynamic> json) {
//     return LeadUpdateData(
//       lead: json["lead"] == null
//           ? null
//           : LeadUpdateLead.fromJson(json["lead"] as Map<String, dynamic>),
//       quotation: json["quotation"] == null
//           ? null
//           : LeadUpdateQuotation.fromJson(json["quotation"] as Map<String, dynamic>),
//     );
//   }

//   Map<String, dynamic> toJson() => <String, dynamic>{
//         if (lead != null) "lead": lead!.toJson(),
//         if (quotation != null) "quotation": quotation!.toJson(),
//       };
// }

// /// Lead details in the update response.
// class LeadUpdateLead {
//   final int? id;
//   final String? reference;
//   final String? name;
//   final String? phone;
//   final String? source;
//   final String? assignedTo;
//   final String? createdBy;
//   final String? description;

//   LeadUpdateLead({
//     this.id,
//     this.reference,
//     this.name,
//     this.phone,
//     this.source,
//     this.assignedTo,
//     this.createdBy,
//     this.description,
//   });

//   factory LeadUpdateLead.fromJson(Map<String, dynamic> json) {
//     return LeadUpdateLead(
//       id: _asInt(json["id"]),
//       reference: json["reference"] as String?,
//       name: json["name"] as String?,
//       phone: json["phone"] as String?,
//       source: json["source"] as String?,
//       assignedTo: json["assigned_to"] as String?,
//       createdBy: json["created_by"] as String?,
//       description: json["description"] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() => <String, dynamic>{
//         "id": id,
//         if (reference != null) "reference": reference,
//         if (name != null) "name": name,
//         if (phone != null) "phone": phone,
//         if (source != null) "source": source,
//         if (assignedTo != null) "assigned_to": assignedTo,
//         if (createdBy != null) "created_by": createdBy,
//         if (description != null) "description": description,
//       };
// }

// /// Quotation details in the update response.
// class LeadUpdateQuotation {
//   final int? id;
//   final String? reference;
//   final String? customerName;
//   final String? customerAddress;
//   final String? issueDate;
//   final String? terms;
//   final String? subtotal;
//   final String? discountPercent;
//   final String? taxPercent;
//   final String? total;
//   final List<LeadUpdateQuotationItem>? items;

//   LeadUpdateQuotation({
//     this.id,
//     this.reference,
//     this.customerName,
//     this.customerAddress,
//     this.issueDate,
//     this.terms,
//     this.subtotal,
//     this.discountPercent,
//     this.taxPercent,
//     this.total,
//     this.items,
//   });

//   factory LeadUpdateQuotation.fromJson(Map<String, dynamic> json) {
//     return LeadUpdateQuotation(
//       id: _asInt(json["id"]),
//       reference: json["reference"] as String?,
//       customerName: json["customer_name"] as String?,
//       customerAddress: json["customer_address"] as String?,
//       issueDate: json["issue_date"] as String?,
//       terms: json["terms"] as String?,
//       subtotal: json["subtotal"] as String?,
//       discountPercent: json["discount_percent"] as String?,
//       taxPercent: json["tax_percent"] as String?,
//       total: json["total"] as String?,
//       items: (json["items"] as List?)
//           ?.map((item) => LeadUpdateQuotationItem.fromJson(item as Map<String, dynamic>))
//           .toList(),
//     );
//   }

//   Map<String, dynamic> toJson() => <String, dynamic>{
//         "id": id,
//         if (reference != null) "reference": reference,
//         if (customerName != null) "customer_name": customerName,
//         if (customerAddress != null) "customer_address": customerAddress,
//         if (issueDate != null) "issue_date": issueDate,
//         if (terms != null) "terms": terms,
//         if (subtotal != null) "subtotal": subtotal,
//         if (discountPercent != null) "discount_percent": discountPercent,
//         if (taxPercent != null) "tax_percent": taxPercent,
//         if (total != null) "total": total,
//         if (items != null) "items": items!.map((e) => e.toJson()).toList(),
//       };
// }

// /// A single item inside the quotation.
// class LeadUpdateQuotationItem {
//   final int? id;
//   final String? description;
//   final String? quantity;
//   final String? rate;
//   final String? basicRate;
//   final String? taxPercent;
//   final String? taxAmount;
//   final String? amount;
//   final int? sortOrder;

//   LeadUpdateQuotationItem({
//     this.id,
//     this.description,
//     this.quantity,
//     this.rate,
//     this.basicRate,
//     this.taxPercent,
//     this.taxAmount,
//     this.amount,
//     this.sortOrder,
//   });

//   factory LeadUpdateQuotationItem.fromJson(Map<String, dynamic> json) {
//     return LeadUpdateQuotationItem(
//       id: _asInt(json["id"]),
//       description: json["description"] as String?,
//       quantity: json["quantity"] as String?,
//       rate: json["rate"] as String?,
//       basicRate: json["basic_rate"] as String?,
//       taxPercent: json["tax_percent"] as String?,
//       taxAmount: json["tax_amount"] as String?,
//       amount: json["amount"] as String?,
//       sortOrder: _asInt(json["sort_order"]),
//     );
//   }

//   Map<String, dynamic> toJson() => <String, dynamic>{
//         "id": id,
//         if (description != null) "description": description,
//         if (quantity != null) "quantity": quantity,
//         if (rate != null) "rate": rate,
//         if (basicRate != null) "basic_rate": basicRate,
//         if (taxPercent != null) "tax_percent": taxPercent,
//         if (taxAmount != null) "tax_amount": taxAmount,
//         if (amount != null) "amount": amount,
//         if (sortOrder != null) "sort_order": sortOrder,
//       };
// }

// /// Helper to safely convert to int.
// int? _asInt(dynamic value) {
//   if (value is int) return value;
//   if (value is String) return int.tryParse(value.trim());
//   return null;
// } 

// --- IGNORE ---