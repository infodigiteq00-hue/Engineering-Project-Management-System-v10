import React, { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Calendar, Clock, Send, Download, TrendingUp, X, FileText, ExternalLink, Eye, MessageSquare } from "lucide-react";
import { fastAPI } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";

interface RevisionEvent {
  id: string;
  event_type: 'submitted' | 'received';
  revision_number: string;
  event_date: string;
  estimated_return_date?: string;
  target_submission_date?: string; // Target date for next submission (for received events)
  actual_return_date?: string;
  days_elapsed?: number;
  notes?: string;
  document_url?: string;
  created_by_user?: {
    full_name?: string;
    email?: string;
  };
}

interface VDCRRevisionHistoryProps {
  vdcrRecordId: string;
  documentName: string;
  currentRevision?: string; // Current revision number from VDCR record
  documentUrl?: string; // Current document URL
  projectId?: string; // Project ID to fetch latest revision
  projectDocumentationStartDate?: string | null; // Custom documentation start date for this VDCR entry
  targetedFinishDate?: string | null; // Target completion date for this VDCR document
  isOpen: boolean;
  onClose: () => void;
  onDocumentClick?: (url: string, name: string) => void; // Callback for document click
}

const VDCRRevisionHistory: React.FC<VDCRRevisionHistoryProps> = ({
  vdcrRecordId,
  documentName,
  currentRevision,
  documentUrl,
  projectId,
  projectDocumentationStartDate,
  targetedFinishDate,
  isOpen,
  onClose,
  onDocumentClick
}) => {
  const { toast } = useToast();
  const [events, setEvents] = useState<RevisionEvent[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [latestRevision, setLatestRevision] = useState<string | undefined>(currentRevision);
  const [projectData, setProjectData] = useState<{ sales_order_date?: string } | null>(null);

  useEffect(() => {
    if (isOpen && vdcrRecordId) {
      loadRevisionEvents();
      loadLatestRevision();
      loadProjectData();
    }
  }, [isOpen, vdcrRecordId, currentRevision, projectDocumentationStartDate]);

  // Update latest revision when currentRevision prop changes
  useEffect(() => {
    if (currentRevision) {
      setLatestRevision(currentRevision);
    }
  }, [currentRevision]);

  const loadLatestRevision = async () => {
    try {
      // Fetch the latest VDCR record by project to get current revision
      if (projectId) {
        const response = await fastAPI.getVDCRRecordsByProject(projectId);
        // Search through all records to find the one we need
        const record = (response as any[]).find((r: any) => r.id === vdcrRecordId);
        if (record && record.revision) {
          setLatestRevision(record.revision);
          return;
        }
      }
      // Fallback to prop if fetch fails or no projectId
      if (currentRevision) {
        setLatestRevision(currentRevision);
      }
    } catch (error) {
      // Silently fail - use the prop value
      if (currentRevision) {
        setLatestRevision(currentRevision);
      }
    }
  };

  const loadProjectData = async () => {
    if (projectId) {
      try {
        const project = await fastAPI.getProjectById(projectId);
        if (project && project.length > 0) {
          setProjectData(project[0]);
        }
      } catch (error) {
        console.error('Error loading project data:', error);
      }
    }
  };

  const loadRevisionEvents = async () => {
    try {
      setIsLoading(true);
      const data = await fastAPI.getVDCRRevisionEvents(vdcrRecordId);
      console.log('📋 Loaded revision events:', data);
      // Log document URLs for debugging
      if (Array.isArray(data)) {
        data.forEach((event: RevisionEvent) => {
          if (event.document_url) {
            console.log(`📄 Revision ${event.revision_number} - ${event.event_type}: Document URL = ${event.document_url}`);
          } else {
            console.log(`⚠️ Revision ${event.revision_number} - ${event.event_type}: No document URL`);
          }
        });
      }
      setEvents(data || []);
    } catch (error) {
      console.error('Error loading revision events:', error);
      toast({ title: 'Error', description: 'Failed to load revision history.', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  // SIMPLE: Normalize ANY date input to YYYY-MM-DD format using LOCAL time (matches UI display)
  const normalizeDate = (dateInput: string | Date | null | undefined): string | null => {
    if (!dateInput) return null;
    
    // If already in YYYY-MM-DD format, return as is
    if (typeof dateInput === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(dateInput)) {
      return dateInput;
    }
    
    // Parse the date and extract LOCAL date components (matches what user sees in UI)
    const date = new Date(dateInput);
    if (isNaN(date.getTime())) return null;
    
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  // SIMPLE: Calculate days between two YYYY-MM-DD date strings
  const calculateDaysBetween = (startDate: string, endDate: string): number => {
    // Both should already be in YYYY-MM-DD format
    if (!startDate || !endDate) return 0;
    
    // Parse as simple date strings (no timezone conversion)
    const startParts = startDate.split('-');
    const endParts = endDate.split('-');
    
    if (startParts.length !== 3 || endParts.length !== 3) return 0;
    
    const start = new Date(parseInt(startParts[0]), parseInt(startParts[1]) - 1, parseInt(startParts[2]));
    const end = new Date(parseInt(endParts[0]), parseInt(endParts[1]) - 1, parseInt(endParts[2]));
    
    const diffTime = end.getTime() - start.getTime();
    const days = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    return Math.max(0, days);
  };

  // Group events by revision and calculate per-revision stats
  const getRevisionTracking = () => {
    if (events.length === 0) return { revisions: [], stats: null };

    // Sort events chronologically
    const sortedEvents = [...events].sort((a, b) => 
      new Date(a.event_date).getTime() - new Date(b.event_date).getTime()
    );

    // Group by revision
    const revisionMap = new Map<string, { submitted?: RevisionEvent; received?: RevisionEvent }>();
    
    sortedEvents.forEach(event => {
      const rev = event.revision_number || '00';
      if (!revisionMap.has(rev)) {
        revisionMap.set(rev, {});
      }
      const revData = revisionMap.get(rev)!;
      if (event.event_type === 'submitted') {
        revData.submitted = event;
      } else if (event.event_type === 'received') {
        revData.received = event;
      }
    });

    // Process revisions
    const revisions: Array<{
      revision: string;
      sentDate: string | null;
      receivedDate: string | null;
      sentEvent: RevisionEvent | null;
      receivedEvent: RevisionEvent | null;
      daysWithClient: number;
      daysWithUs: number;
      documentUrl: string | null;
      targetSubmissionDate: string | null; // Target date from previous revision's received event
    }> = [];

    const sortedRevisions = Array.from(revisionMap.entries()).sort((a, b) => {
      const aNum = parseInt(a[0].replace(/[^0-9]/g, '')) || 0;
      const bNum = parseInt(b[0].replace(/[^0-9]/g, '')) || 0;
      return aNum - bNum;
    });

    let totalDaysWithClient = 0;
    let totalDaysWithUs = 0;
    let previousReceivedDate: string | null = null; // Receipt date of previous revision

    sortedRevisions.forEach(([rev, revEvents], index) => {
      const revNum = parseInt(rev.replace(/[^0-9]/g, '') || '0');
      const sentDate = revEvents.submitted?.event_date || null;
      const receivedDate = revEvents.received?.event_date || null;
      const sentEvent = revEvents.submitted || null;
      const receivedEvent = revEvents.received || null;

      // SIMPLE: Calculate days with client (only if received)
      let daysWithClient = 0;
      if (sentDate && receivedDate) {
        const sentDateOnly = normalizeDate(sentDate);
        const receivedDateOnly = normalizeDate(receivedDate);
        if (sentDateOnly && receivedDateOnly) {
          daysWithClient = calculateDaysBetween(sentDateOnly, receivedDateOnly);
          totalDaysWithClient += daysWithClient;
        }
      }

      // SIMPLE: Calculate days with us
      let daysWithUs = 0;
      if (revNum === 0 && sentDate) {
        // Rev-00: Start Date → Sent Date
        const startDate = normalizeDate(projectDocumentationStartDate) || normalizeDate(projectData?.sales_order_date);
        const sentDateOnly = normalizeDate(sentDate);
        if (startDate && sentDateOnly) {
          daysWithUs = calculateDaysBetween(startDate, sentDateOnly);
          totalDaysWithUs += daysWithUs;
        }
      } else if (sentDate && previousReceivedDate) {
        // Other revisions: Previous Received Date → Current Sent Date
        const prevDateOnly = normalizeDate(previousReceivedDate);
        const sentDateOnly = normalizeDate(sentDate);
        if (prevDateOnly && sentDateOnly) {
          daysWithUs = calculateDaysBetween(prevDateOnly, sentDateOnly);
          totalDaysWithUs += daysWithUs;
        }
      }
      // Note: For the first revision (Rev-00), if there's no submission date yet,
      // we don't calculate days with us (it's still in progress)

      // Get document URL - prioritize document_url from events, fallback to current document URL
      let docUrl: string | null = null;
      
      // For sent events, use the submitted event's document_url
      if (sentEvent?.document_url) {
        docUrl = sentEvent.document_url;
      }
      // For received events, use the received event's document_url (if different from sent)
      else if (receivedEvent?.document_url) {
        docUrl = receivedEvent.document_url;
      }
      // Fallback to current document URL if revision matches current revision
      else if (rev === currentRevision && documentUrl) {
        docUrl = documentUrl;
      }

      // Get target submission date from previous revision's received event
      // This will be shown under "Sent to Client" for the current revision
      let targetSubmissionDate: string | null = null;
      if (index > 0) {
        // Look at previous revision's received event for target_submission_date
        const prevRevision = revisions[index - 1];
        if (prevRevision.receivedEvent?.target_submission_date) {
          targetSubmissionDate = prevRevision.receivedEvent.target_submission_date;
        }
      }

      revisions.push({
        revision: rev,
        sentDate,
        receivedDate,
        sentEvent,
        receivedEvent,
        daysWithClient,
        daysWithUs,
        documentUrl: docUrl,
        targetSubmissionDate // Target date from previous revision's received event
      });

      // Update previousReceivedDate for next iteration
      // Store the raw date string - we'll normalize it when calculating
      if (receivedDate) {
        previousReceivedDate = receivedDate;
      }
    });

    // SIMPLE: No "remaining days" logic needed
    // We only calculate days when we have both: previous received date AND current sent date
    // If document is received but not sent again, we just don't calculate anything yet

    // Calculate total days (sum of days with us and days with client)
    const totalDays = totalDaysWithUs + totalDaysWithClient;
    
    // Calculate days to go (from today to targeted finish date)
    let daysToGo: number | null = null;
    if (targetedFinishDate) {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const targetDate = new Date(targetedFinishDate);
      targetDate.setHours(0, 0, 0, 0);
      const diffTime = targetDate.getTime() - today.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      daysToGo = diffDays;
    }

    return {
      revisions,
      stats: {
        totalDaysWithClient,
        totalDaysWithUs,
        totalDays,
        daysToGo
      }
    };
  };

  const revisionTracking = getRevisionTracking();


  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const formatDateShort = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const formatDateOnly = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };


  // Get last event information
  const getLastEventInfo = () => {
    if (events.length === 0) return null;

    const sortedEvents = [...events].sort((a, b) => 
      new Date(b.event_date).getTime() - new Date(a.event_date).getTime()
    );
    
    const lastEvent = sortedEvents[0];
    const daysSince = calculateDaysBetween(lastEvent.event_date, new Date().toISOString());
    
    // Use latest revision (fetched fresh) if available, otherwise use prop, otherwise fall back to event's revision
    const displayRevision = latestRevision || currentRevision || lastEvent.revision_number;
    
    return {
      event: lastEvent,
      daysSince,
      eventTypeText: lastEvent.event_type === 'submitted' ? 'Submitted' : 'Received',
      date: formatDateShort(lastEvent.event_date),
      revision: displayRevision
    };
  };

  const lastEventInfo = getLastEventInfo();

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader className="pb-4 border-b border-gray-200">
          <DialogTitle className="text-2xl font-semibold text-gray-800">
            Revision History - {documentName}
          </DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Last Event Highlight - Primary Display */}
            {lastEventInfo && (
              <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
                <div className="p-5">
                  <div className="flex items-center justify-between gap-6">
                    {/* Left: Icon and Days */}
                    <div className="flex items-center gap-4">
                      <div className={`p-4 rounded-lg border ${
                        lastEventInfo.event.event_type === 'submitted' 
                          ? 'bg-blue-50 border-blue-200' 
                          : 'bg-green-50 border-green-200'
                      }`}>
                        {lastEventInfo.event.event_type === 'submitted' ? (
                          <Send className="w-8 h-8 text-blue-600" />
                        ) : (
                          <Download className="w-8 h-8 text-green-600" />
                        )}
                      </div>
                      <div>
                        <div className="text-xs text-gray-500 uppercase tracking-wide mb-1">Last Event</div>
                        <div className="text-3xl font-bold text-gray-900">
                          {lastEventInfo.daysSince}
                        </div>
                        <div className="text-sm text-gray-600 font-medium">days ago</div>
                      </div>
                    </div>

                    {/* Middle: Event Type and Revision */}
                    <div className="flex-1 flex items-center gap-4">
                      <div className="h-12 w-px bg-gray-300"></div>
                      <div>
                        <div className="text-xs text-gray-500 uppercase tracking-wide mb-2">Event Type</div>
                        <div className="flex items-center gap-2">
                          <Badge className={`text-sm px-3 py-1 border ${
                            lastEventInfo.event.event_type === 'submitted'
                              ? 'bg-blue-50 text-blue-700 border-blue-300'
                              : 'bg-green-50 text-green-700 border-green-300'
                          }`}>
                            {lastEventInfo.eventTypeText}
                          </Badge>
                          {lastEventInfo.revision && (
                            <Badge variant="outline" className="font-mono text-sm px-3 py-1 bg-white">
                              {lastEventInfo.revision.replace(/^Rev\s+Rev/i, 'Rev-').replace(/^Rev\s+/i, '')}
                            </Badge>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Right: Date and User */}
                    <div className="flex items-center gap-4">
                      <div className="h-12 w-px bg-gray-300"></div>
                      <div className="text-right">
                        <div className="text-xs text-gray-500 uppercase tracking-wide mb-2">Date</div>
                        <div className="flex items-center gap-2 text-gray-800 font-semibold">
                          <Calendar className="w-4 h-4 text-gray-500" />
                          <span>{lastEventInfo.date}</span>
                        </div>
                        {lastEventInfo.event.created_by_user && (
                          <div className="text-xs text-gray-600 mt-1">
                            by {lastEventInfo.event.created_by_user.full_name || lastEventInfo.event.created_by_user.email || 'Unknown'}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Project Documentation Start Date and Targeted Finish Date - Single Row */}
            <div className="flex items-center justify-between gap-4 p-4 bg-gray-50 rounded-lg border border-gray-200 mb-4">
              {/* Project Documentation Start Date - Left */}
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4 text-blue-600" />
                <div>
                  <div className="text-xs font-semibold text-gray-700">Project Documentation Start Date</div>
                  {(() => {
                    const startDate = projectDocumentationStartDate || projectData?.sales_order_date;
                    if (startDate) {
                      const date = new Date(startDate);
                      const formattedDate = date.toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric'
                      });
                      return (
                        <div className="text-sm text-blue-700 font-medium">{formattedDate}</div>
                      );
                    }
                    return <div className="text-sm text-gray-500">Not set</div>;
                  })()}
                </div>
              </div>

              {/* Targeted Finish Date - Right */}
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4 text-orange-600" />
                <div>
                  <div className="text-xs font-semibold text-gray-700">Targeted Finish Date</div>
                  {targetedFinishDate ? (
                    <div className="text-sm text-orange-700 font-medium">
                      {new Date(targetedFinishDate).toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric'
                      })}
                    </div>
                  ) : (
                    <div className="text-sm text-gray-500">Not set</div>
                  )}
                </div>
              </div>
            </div>

            {/* Statistics Summary */}
            {revisionTracking.stats && (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-5 border border-gray-200 rounded-lg bg-gray-50/30">
                <div className="text-center">
                  <div className="text-2xl font-semibold text-blue-600">{revisionTracking.stats.totalDaysWithUs}</div>
                  <div className="text-xs text-gray-600 mt-1">Total Days with Us</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-semibold text-purple-600">{revisionTracking.stats.totalDaysWithClient}</div>
                  <div className="text-xs text-gray-600 mt-1">Total Days with Client</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-semibold text-green-600">{revisionTracking.stats.totalDays ?? 0}</div>
                  <div className="text-xs text-gray-600 mt-1">Total Days</div>
                </div>
                <div className="text-center">
                  <div className={`text-2xl font-semibold ${revisionTracking.stats.daysToGo !== null ? (revisionTracking.stats.daysToGo < 0 ? 'text-red-600' : revisionTracking.stats.daysToGo <= 7 ? 'text-orange-600' : 'text-indigo-600') : 'text-gray-400'}`}>
                    {revisionTracking.stats.daysToGo !== null ? revisionTracking.stats.daysToGo : '-'}
                  </div>
                  <div className="text-xs text-gray-600 mt-1">Days to Go</div>
                </div>
              </div>
            )}

            {/* Revision History by Revision */}
            <div className="space-y-4 pt-2">
              <h3 className="text-lg font-semibold text-gray-800">Revision History</h3>
              {revisionTracking.revisions.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <Clock className="w-12 h-12 mx-auto mb-2 text-gray-400" />
                  <p>No revision events recorded yet.</p>
                  <p className="text-sm mt-1">Start tracking by submitting or receiving documents.</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {revisionTracking.revisions.map((rev, idx) => {
                    const revNum = parseInt(rev.revision.replace(/[^0-9]/g, '') || '0');
                    
                    return (
                      <div key={idx} className="bg-white rounded-lg border border-gray-200 p-5 shadow-sm">
                        <div className="flex items-center justify-between mb-4 pb-3 border-b border-gray-100">
                          <Badge variant="outline" className="text-sm font-mono px-3 py-1 bg-gray-50 border-gray-300 text-gray-700">
                            {rev.revision}
                          </Badge>
                        </div>

                        <div className="space-y-3">
                            {/* Sent to Client */}
                            <div className="flex items-start gap-4 p-4 rounded-lg border-l-2 border-blue-300">
                              <div className="flex-shrink-0 p-2 bg-blue-50 border border-blue-200 rounded-lg">
                                <Send className="w-5 h-5 text-blue-600" />
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="text-sm font-semibold text-gray-800 mb-2">Sent to Client for Approval</div>
                                {rev.sentDate ? (
                                  <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-sm text-gray-700">
                                      <Calendar className="w-4 h-4 text-gray-500" />
                                      <span className="font-medium">{formatDate(rev.sentDate)}</span>
                                    </div>
                                    {/* Show Target Submission Date (from previous revision's received event) */}
                                    {rev.targetSubmissionDate && (
                                      <div className="space-y-1">
                                        <div className="flex items-center gap-2 text-xs text-gray-700">
                                          <Calendar className="w-3.5 h-3.5" />
                                          <span className="font-medium">Target Submission:</span>
                                          <span className="text-gray-800">{formatDateOnly(rev.targetSubmissionDate)}</span>
                                        </div>
                                        {(() => {
                                          const targetDate = new Date(rev.targetSubmissionDate);
                                          targetDate.setHours(0, 0, 0, 0);
                                          const actualDate = new Date(rev.sentDate!);
                                          actualDate.setHours(0, 0, 0, 0);
                                          
                                          const timeDiff = actualDate.getTime() - targetDate.getTime();
                                          const daysDiff = Math.abs(Math.ceil(timeDiff / (1000 * 60 * 60 * 24)));
                                          
                                          // Determine status: early, on time, or late
                                          let statusText = '';
                                          let isGood = false;
                                          
                                          if (timeDiff < 0) {
                                            // Sent before target date (early)
                                            statusText = `${daysDiff} days early`;
                                            isGood = true;
                                          } else if (timeDiff === 0 || daysDiff === 0) {
                                            // Sent exactly on target date (on time)
                                            statusText = 'on time';
                                            isGood = true;
                                          } else {
                                            // Sent after target date (late)
                                            statusText = `${daysDiff} days late`;
                                            isGood = false;
                                          }
                                          
                                          return (
                                            <div className={`text-xs font-bold px-2 py-0.5 rounded inline-block ${isGood ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                                              {isGood ? '✓' : '✗'} {statusText}
                                            </div>
                                          );
                                        })()}
                                      </div>
                                    )}
                                  </div>
                                ) : (
                                  <div className="text-sm text-gray-500 italic">Not sent yet</div>
                                )}
                              </div>
                              {rev.sentEvent?.notes && (
                                <div className="flex-shrink-0 w-[250px]">
                                  <div className="flex items-center gap-1.5 text-xs text-gray-600 mb-1.5">
                                    <MessageSquare className="w-3.5 h-3.5" />
                                    <span className="font-semibold">Remarks</span>
                                  </div>
                                  <div className="text-xs text-gray-700 bg-white p-2.5 rounded-md border border-gray-300 shadow-sm break-words leading-relaxed">{rev.sentEvent.notes}</div>
                                </div>
                              )}
                            </div>

                            {/* Received from Client */}
                            <div className="flex items-start gap-4 p-4 rounded-lg border-l-2 border-green-300">
                              <div className="flex-shrink-0 p-2 bg-green-50 border border-green-200 rounded-lg">
                                <Download className="w-5 h-5 text-green-600" />
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="text-sm font-semibold text-gray-800 mb-2">Received from Client with Comments</div>
                                {rev.receivedDate ? (
                                  <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-sm text-gray-700">
                                      <Calendar className="w-4 h-4 text-gray-500" />
                                      <span className="font-medium">{formatDate(rev.receivedDate)}</span>
                                    </div>
                                    {/* Show Expected Return Date (from current revision's submitted event) */}
                                    {rev.sentEvent?.estimated_return_date && (
                                      <div className="space-y-1">
                                        <div className="flex items-center gap-2 text-xs text-gray-700">
                                          <Calendar className="w-3.5 h-3.5" />
                                          <span className="font-medium">Expected Return:</span>
                                          <span className="text-gray-800">{formatDateOnly(rev.sentEvent.estimated_return_date)}</span>
                                        </div>
                                        {(() => {
                                          const expectedDate = new Date(rev.sentEvent.estimated_return_date);
                                          expectedDate.setHours(0, 0, 0, 0);
                                          const receivedDate = new Date(rev.receivedDate);
                                          receivedDate.setHours(0, 0, 0, 0);
                                          
                                          const timeDiff = receivedDate.getTime() - expectedDate.getTime();
                                          const daysDiff = Math.abs(Math.ceil(timeDiff / (1000 * 60 * 60 * 24)));
                                          
                                          // Determine status: early, on time, or late
                                          let statusText = '';
                                          let isGood = false;
                                          
                                          if (timeDiff < 0) {
                                            // Received before expected date (early)
                                            statusText = `${daysDiff} days early`;
                                            isGood = true;
                                          } else if (timeDiff === 0 || daysDiff === 0) {
                                            // Received exactly on expected date (on time)
                                            statusText = 'on time';
                                            isGood = true;
                                          } else {
                                            // Received after expected date (late)
                                            statusText = `${daysDiff} days late`;
                                            isGood = false;
                                          }
                                          
                                          return (
                                            <div className={`text-xs font-bold px-2 py-0.5 rounded inline-block ${isGood ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                                              {isGood ? '✓' : '✗'} {statusText}
                                            </div>
                                          );
                                        })()}
                                      </div>
                                    )}
                                  </div>
                                ) : (
                                  <div className="text-sm text-gray-500 italic">Not received yet</div>
                                )}
                              </div>
                              {rev.receivedEvent?.notes && (
                                <div className="flex-shrink-0 w-[250px]">
                                  <div className="flex items-center gap-1.5 text-xs text-gray-600 mb-1.5">
                                    <MessageSquare className="w-3.5 h-3.5" />
                                    <span className="font-semibold">Remarks</span>
                                  </div>
                                  <div className="text-xs text-gray-700 bg-white p-2.5 rounded-md border border-gray-300 shadow-sm break-words leading-relaxed">{rev.receivedEvent.notes}</div>
                                </div>
                              )}
                            </div>

                            {/* Statistics and Preview */}
                            <div className="pt-3 border-t border-gray-200">
                                <div className="grid grid-cols-3 gap-3 mb-3">
                                  {rev.sentDate && rev.receivedDate ? (
                                    <div className="text-center p-2 rounded border border-purple-200 bg-purple-50/30">
                                      <div className="text-lg font-semibold text-purple-600">{rev.daysWithClient}</div>
                                      <div className="text-xs text-gray-600">Days with Client</div>
                                    </div>
                                  ) : (
                                    <div className="text-center p-2 rounded border border-gray-200">
                                      <div className="text-lg font-semibold text-gray-400">-</div>
                                      <div className="text-xs text-gray-600">Days with Client</div>
                                    </div>
                                  )}
                                  <div className="text-center p-2 rounded border border-blue-200 bg-blue-50/30">
                                    <div className="text-lg font-semibold text-blue-600">{rev.daysWithUs}</div>
                                    <div className="text-xs text-gray-600">Days with Us</div>
                                  </div>
                                  {rev.sentDate ? (
                                    <div className="text-center p-2 rounded border border-indigo-200 bg-indigo-50/30">
                                      <div className="text-lg font-semibold text-indigo-600">{rev.daysWithClient + rev.daysWithUs}</div>
                                      <div className="text-xs text-gray-600">Total Days</div>
                                    </div>
                                  ) : (
                                    <div className="text-center p-2 rounded border border-gray-200">
                                      <div className="text-lg font-semibold text-gray-400">-</div>
                                      <div className="text-xs text-gray-600">Total Days</div>
                                    </div>
                                  )}
                                </div>
                                <div className="flex gap-2">
                                  <button
                                    onClick={() => {
                                      const docUrl = rev.sentEvent?.document_url;
                                      if (docUrl && onDocumentClick) {
                                        onDocumentClick(docUrl, `${documentName} - ${rev.revision} - Submitted`);
                                      }
                                    }}
                                    disabled={!rev.sentEvent?.document_url || !onDocumentClick}
                                    className={`flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-medium rounded-md transition-colors border ${
                                      rev.sentEvent?.document_url && onDocumentClick
                                        ? 'text-blue-600 bg-white border-blue-300 hover:bg-blue-50 cursor-pointer'
                                        : 'text-gray-400 bg-gray-50 border-gray-200 cursor-not-allowed'
                                    }`}
                                  >
                                    <Eye className="w-3.5 h-3.5" />
                                    <span>Preview Sent Doc</span>
                                  </button>
                                  <button
                                    onClick={() => {
                                      const docUrl = rev.receivedEvent?.document_url;
                                      if (docUrl && onDocumentClick) {
                                        onDocumentClick(docUrl, `${documentName} - ${rev.revision} - Commented`);
                                      }
                                    }}
                                    disabled={!rev.receivedEvent?.document_url || !onDocumentClick}
                                    className={`flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-medium rounded-md transition-colors border ${
                                      rev.receivedEvent?.document_url && onDocumentClick
                                        ? 'text-green-600 bg-white border-green-300 hover:bg-green-50 cursor-pointer'
                                        : 'text-gray-400 bg-gray-50 border-gray-200 cursor-not-allowed'
                                    }`}
                                  >
                                    <Eye className="w-3.5 h-3.5" />
                                    <span>Preview Received Doc</span>
                                  </button>
                                </div>
                              </div>

                          </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default VDCRRevisionHistory;

