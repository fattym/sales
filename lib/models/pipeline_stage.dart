enum PipelineStage {
  lead,
  contacted,
  meetingScheduled,
  sampleIssued,
  quotationSent,
  decisionPending,
  negotiation,
  won,
  lost,
  dormant,
}

extension PipelineStageX on PipelineStage {
  String get dbValue {
    switch (this) {
      case PipelineStage.lead:
        return 'lead';
      case PipelineStage.contacted:
        return 'contacted';
      case PipelineStage.meetingScheduled:
        return 'meeting_scheduled';
      case PipelineStage.sampleIssued:
        return 'sample_issued';
      case PipelineStage.quotationSent:
        return 'quotation_sent';
      case PipelineStage.decisionPending:
        return 'decision_pending';
      case PipelineStage.negotiation:
        return 'negotiation';
      case PipelineStage.won:
        return 'won';
      case PipelineStage.lost:
        return 'lost';
      case PipelineStage.dormant:
        return 'dormant';
    }
  }

  String get label {
    switch (this) {
      case PipelineStage.lead:
        return 'Lead';
      case PipelineStage.contacted:
        return 'Contacted';
      case PipelineStage.meetingScheduled:
        return 'Meeting Scheduled';
      case PipelineStage.sampleIssued:
        return 'Sample Issued';
      case PipelineStage.quotationSent:
        return 'Quotation Sent';
      case PipelineStage.decisionPending:
        return 'Decision Pending';
      case PipelineStage.negotiation:
        return 'Negotiation';
      case PipelineStage.won:
        return 'Won';
      case PipelineStage.lost:
        return 'Lost';
      case PipelineStage.dormant:
        return 'Dormant';
    }
  }

  int get defaultProbability {
    switch (this) {
      case PipelineStage.lead:
        return 10;
      case PipelineStage.contacted:
        return 20;
      case PipelineStage.meetingScheduled:
        return 35;
      case PipelineStage.sampleIssued:
        return 50;
      case PipelineStage.quotationSent:
        return 65;
      case PipelineStage.decisionPending:
        return 75;
      case PipelineStage.negotiation:
        return 85;
      case PipelineStage.won:
        return 100;
      case PipelineStage.lost:
      case PipelineStage.dormant:
        return 0;
    }
  }

  bool get isActive =>
      this != PipelineStage.won &&
      this != PipelineStage.lost &&
      this != PipelineStage.dormant;
}

PipelineStage pipelineStageFromDb(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'lead':
      return PipelineStage.lead;
    case 'contacted':
      return PipelineStage.contacted;
    case 'meeting_scheduled':
      return PipelineStage.meetingScheduled;
    case 'sample_issued':
      return PipelineStage.sampleIssued;
    case 'quotation_sent':
      return PipelineStage.quotationSent;
    case 'decision_pending':
      return PipelineStage.decisionPending;
    case 'negotiation':
      return PipelineStage.negotiation;
    case 'won':
      return PipelineStage.won;
    case 'lost':
      return PipelineStage.lost;
    case 'dormant':
      return PipelineStage.dormant;
    default:
      return PipelineStage.lead;
  }
}

bool canMovePipelineStage(PipelineStage current, PipelineStage next) {
  if (current == next) return true;

  switch (current) {
    case PipelineStage.lead:
      return next == PipelineStage.contacted || next == PipelineStage.lost;
    case PipelineStage.contacted:
      return next == PipelineStage.meetingScheduled ||
          next == PipelineStage.lost ||
          next == PipelineStage.dormant;
    case PipelineStage.meetingScheduled:
      return next == PipelineStage.sampleIssued ||
          next == PipelineStage.quotationSent ||
          next == PipelineStage.lost ||
          next == PipelineStage.dormant;
    case PipelineStage.sampleIssued:
      return next == PipelineStage.quotationSent ||
          next == PipelineStage.decisionPending ||
          next == PipelineStage.lost ||
          next == PipelineStage.dormant;
    case PipelineStage.quotationSent:
      return next == PipelineStage.decisionPending ||
          next == PipelineStage.negotiation ||
          next == PipelineStage.lost ||
          next == PipelineStage.dormant;
    case PipelineStage.decisionPending:
      return next == PipelineStage.negotiation ||
          next == PipelineStage.won ||
          next == PipelineStage.lost ||
          next == PipelineStage.dormant;
    case PipelineStage.negotiation:
      return next == PipelineStage.won ||
          next == PipelineStage.lost ||
          next == PipelineStage.dormant;
    case PipelineStage.won:
      return false;
    case PipelineStage.lost:
      return next == PipelineStage.lead || next == PipelineStage.contacted;
    case PipelineStage.dormant:
      return next == PipelineStage.contacted || next == PipelineStage.lead;
  }
}
