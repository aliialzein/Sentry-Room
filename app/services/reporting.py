from datetime import datetime, timezone
from html import escape
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.emergency_incident import EmergencyIncident
from app.schemas.analytics import AnalyticsActionCount, AnalyticsRange, AnalyticsTypeCount
from app.schemas.reporting import AnalyticsPdfReportData, ReportIncidentSummary
from app.services.ai_reporting import AIReportingService
from app.services.analytics import AnalyticsService


class ReportingService:
    _type_rows = (
        ("Security Threat", ("Security Threat",)),
        ("Fire Emergency", ("Fire Emergency",)),
        ("Medical Emergency", ("Medical Emergency",)),
        ("Humidity Issue", ("Humidity Issue", "High Humidity / Fan Issue")),
        ("General Support", ("General Support",)),
    )

    _action_rows = (
        ("Calls", ("Call", "Calls")),
        ("SMS", ("SMS",)),
        ("Email", ("Email",)),
        ("Share", ("Share",)),
    )

    def __init__(
        self,
        analytics_service: AnalyticsService | None = None,
        ai_reporting_service: AIReportingService | None = None,
    ) -> None:
        self._analytics_service = analytics_service or AnalyticsService()
        self._ai_reporting_service = ai_reporting_service or AIReportingService(
            analytics_service=self._analytics_service,
        )
        self._styles = getSampleStyleSheet()
        self._configure_styles()

    def generate_pdf_report(
        self,
        db: Session,
        report_range: AnalyticsRange,
        user_id: int | None = None,
        include_ai: bool = True,
    ) -> BytesIO:
        data = self._build_report_data(
            db=db,
            report_range=report_range,
            user_id=user_id,
            include_ai=include_ai,
        )
        buffer = BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=letter,
            rightMargin=0.55 * inch,
            leftMargin=0.55 * inch,
            topMargin=0.55 * inch,
            bottomMargin=0.7 * inch,
            title="Sentry Room Emergency Analytics Report",
            author="Sentry Room",
        )

        elements = []
        elements.extend(self._build_header(data))
        elements.extend(self._build_ai_summary_section(data))
        elements.extend(self._build_summary_section(data))
        elements.extend(self._build_type_section(data))
        elements.extend(self._build_action_section(data))
        elements.extend(self._build_trend_section(data))
        elements.extend(self._build_recent_incidents_section(data))

        doc.build(
            elements,
            onFirstPage=self._build_footer,
            onLaterPages=self._build_footer,
        )
        buffer.seek(0)
        return buffer

    def filename(self, report_range: AnalyticsRange) -> str:
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
        return f"sentry-room-emergency-analytics-{report_range.value}-{timestamp}.pdf"

    def _build_report_data(
        self,
        db: Session,
        report_range: AnalyticsRange,
        user_id: int | None,
        include_ai: bool,
    ) -> AnalyticsPdfReportData:
        summary = self._analytics_service.get_summary(db=db, analytics_range=report_range)
        type_breakdown = self._analytics_service.get_counts_by_type(db=db, analytics_range=report_range)
        action_breakdown = self._analytics_service.get_counts_by_action(db=db, analytics_range=report_range)
        trends = self._analytics_service.get_trends(db=db, analytics_range=report_range)
        recent_incidents = self._get_recent_incidents(db=db, report_range=report_range)
        ai_summary = None

        if include_ai and user_id is not None:
            ai_summary = self._ai_reporting_service.safe_generate_summary(
                db=db,
                report_range=report_range,
                user_id=user_id,
            )

        return AnalyticsPdfReportData(
            generated_at=datetime.now(timezone.utc),
            range_label=self._analytics_service.range_label(report_range),
            summary=summary,
            type_breakdown=type_breakdown,
            action_breakdown=action_breakdown,
            trends=trends,
            recent_incidents=recent_incidents,
            ai_summary=ai_summary,
        )

    def _get_recent_incidents(self, db: Session, report_range: AnalyticsRange) -> list[ReportIncidentSummary]:
        start_at = self._analytics_service.range_start_at(report_range)
        statement = (
            select(EmergencyIncident)
            .where(EmergencyIncident.recorded_at >= start_at)
            .order_by(EmergencyIncident.recorded_at.desc())
            .limit(25)
        )
        incidents = db.scalars(statement).all()
        return [
            ReportIncidentSummary(
                recorded_at=incident.recorded_at,
                emergency_type=self._analytics_service.format_emergency_type(incident.emergency_type),
                action_type=self._analytics_service.format_action_type(incident.action_type),
                location=incident.manual_location,
                status=self._format_status(incident.status.value),
            )
            for incident in incidents
        ]

    def _build_header(self, data: AnalyticsPdfReportData) -> list:
        generated_at = data.generated_at.strftime("%Y-%m-%d %H:%M UTC")
        return [
            Paragraph("Sentry Room Emergency Analytics Report", self._styles["ReportTitle"]),
            Spacer(1, 0.12 * inch),
            Paragraph(f"<b>Report generated:</b> {generated_at}", self._styles["BodySmall"]),
            Paragraph(f"<b>Selected range:</b> {escape(data.range_label)}", self._styles["BodySmall"]),
            Spacer(1, 0.22 * inch),
        ]

    def _build_summary_section(self, data: AnalyticsPdfReportData) -> list:
        summary = data.summary
        rows = [
            ["Metric", "Value"],
            ["Total Incidents", str(summary.total_incidents)],
            ["Pending Sync", str(summary.pending_sync)],
            ["Successful Actions", str(summary.successful_actions)],
            ["Failed Actions", str(summary.failed_actions)],
            ["Most Common Emergency", escape(summary.most_common_type or "None")],
        ]
        return self._section_with_table("Executive Statistics", rows, col_widths=[3.2 * inch, 3.0 * inch])

    def _build_ai_summary_section(self, data: AnalyticsPdfReportData) -> list:
        ai_summary = data.ai_summary
        if ai_summary is None:
            return self._section_with_paragraphs(
                "Executive AI Summary",
                ["AI summary unavailable."],
            )

        paragraphs = [ai_summary.summary or "AI summary unavailable."]
        if ai_summary.key_findings:
            paragraphs.append("Key Findings")
            paragraphs.extend([f"- {finding}" for finding in ai_summary.key_findings])
        if ai_summary.recommendations:
            paragraphs.append("Recommendations")
            paragraphs.extend([f"- {recommendation}" for recommendation in ai_summary.recommendations])

        return self._section_with_paragraphs("Executive AI Summary", paragraphs)

    def _build_type_section(self, data: AnalyticsPdfReportData) -> list:
        counts = self._count_map(data.type_breakdown)
        rows = [["Emergency Type", "Count"]]
        for label, aliases in self._type_rows:
            rows.append([label, str(self._first_count(counts, aliases))])
        return self._section_with_table("Emergency Type Breakdown", rows, col_widths=[4.3 * inch, 1.9 * inch])

    def _build_action_section(self, data: AnalyticsPdfReportData) -> list:
        counts = self._count_map(data.action_breakdown)
        rows = [["Action", "Count"]]
        for label, aliases in self._action_rows:
            rows.append([label, str(self._first_count(counts, aliases))])
        return self._section_with_table("Action Breakdown", rows, col_widths=[4.3 * inch, 1.9 * inch])

    def _build_trend_section(self, data: AnalyticsPdfReportData) -> list:
        rows = [["Date", "Incident Count"]]
        if data.trends:
            rows.extend([[trend.date.isoformat(), str(trend.count)] for trend in data.trends])
        else:
            rows.append(["No trend data available", "0"])
        return self._section_with_table("Trend Analysis Table", rows, col_widths=[3.1 * inch, 3.1 * inch])

    def _build_recent_incidents_section(self, data: AnalyticsPdfReportData) -> list:
        rows = [["Date", "Type", "Action", "Location", "Status"]]
        if data.recent_incidents:
            rows.extend(
                [
                    [
                        incident.recorded_at.strftime("%Y-%m-%d %H:%M"),
                        self._paragraph(incident.emergency_type),
                        self._paragraph(incident.action_type),
                        self._paragraph(incident.location),
                        self._paragraph(incident.status),
                    ]
                    for incident in data.recent_incidents
                ]
            )
        else:
            rows.append(["No incidents available", "", "", "", ""])

        return self._section_with_table(
            "Incident Summary Table",
            rows,
            col_widths=[1.15 * inch, 1.35 * inch, 0.8 * inch, 2.0 * inch, 0.9 * inch],
        )

    def _build_footer(self, canvas, doc) -> None:
        canvas.saveState()
        canvas.setStrokeColor(HexColor("#D1D5DB"))
        canvas.setLineWidth(0.4)
        canvas.line(doc.leftMargin, 0.52 * inch, letter[0] - doc.rightMargin, 0.52 * inch)
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(HexColor("#4B5563"))
        canvas.drawString(doc.leftMargin, 0.34 * inch, "Generated by Sentry Room")
        canvas.drawRightString(letter[0] - doc.rightMargin, 0.34 * inch, f"Page {doc.page}")
        canvas.restoreState()

    def _section_with_table(self, title: str, rows: list, col_widths: list[float]) -> list:
        table = Table(rows, colWidths=col_widths, repeatRows=1, hAlign="LEFT")
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), HexColor("#111827")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8.6),
                    ("TEXTCOLOR", (0, 1), (-1, -1), HexColor("#111827")),
                    ("BACKGROUND", (0, 1), (-1, -1), HexColor("#F9FAFB")),
                    ("GRID", (0, 0), (-1, -1), 0.35, HexColor("#D1D5DB")),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [HexColor("#FFFFFF"), HexColor("#F3F4F6")]),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 7),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                    ("TOPPADDING", (0, 0), (-1, -1), 6),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ]
            )
        )
        return [
            Paragraph(title, self._styles["SectionTitle"]),
            Spacer(1, 0.08 * inch),
            table,
            Spacer(1, 0.22 * inch),
        ]

    def _section_with_paragraphs(self, title: str, paragraphs: list[str]) -> list:
        elements = [
            Paragraph(title, self._styles["SectionTitle"]),
            Spacer(1, 0.08 * inch),
        ]
        for paragraph in paragraphs:
            style = self._styles["BodySmall"]
            if paragraph in {"Key Findings", "Recommendations"}:
                style = self._styles["SectionSubTitle"]
            elements.append(Paragraph(escape(paragraph), style))
            elements.append(Spacer(1, 0.05 * inch))
        elements.append(Spacer(1, 0.12 * inch))
        return elements

    def _configure_styles(self) -> None:
        self._styles.add(
            ParagraphStyle(
                name="ReportTitle",
                parent=self._styles["Title"],
                alignment=TA_CENTER,
                fontName="Helvetica-Bold",
                fontSize=20,
                leading=24,
                textColor=HexColor("#111827"),
                spaceAfter=4,
            )
        )
        self._styles.add(
            ParagraphStyle(
                name="SectionTitle",
                parent=self._styles["Heading2"],
                alignment=TA_LEFT,
                fontName="Helvetica-Bold",
                fontSize=13,
                leading=16,
                textColor=HexColor("#111827"),
                spaceBefore=4,
                spaceAfter=4,
            )
        )
        self._styles.add(
            ParagraphStyle(
                name="BodySmall",
                parent=self._styles["BodyText"],
                fontName="Helvetica",
                fontSize=9,
                leading=12,
                textColor=HexColor("#374151"),
            )
        )
        self._styles.add(
            ParagraphStyle(
                name="SectionSubTitle",
                parent=self._styles["BodyText"],
                fontName="Helvetica-Bold",
                fontSize=9.5,
                leading=12,
                textColor=HexColor("#111827"),
                spaceBefore=4,
            )
        )
        self._styles.add(
            ParagraphStyle(
                name="TableBody",
                parent=self._styles["BodyText"],
                fontName="Helvetica",
                fontSize=8.2,
                leading=10,
                textColor=HexColor("#111827"),
            )
        )

    def _paragraph(self, value: str) -> Paragraph:
        return Paragraph(escape(value or ""), self._styles["TableBody"])

    def _count_map(self, items: list[AnalyticsTypeCount] | list[AnalyticsActionCount]) -> dict[str, int]:
        return {self._item_label(item): item.count for item in items}

    def _item_label(self, item: AnalyticsTypeCount | AnalyticsActionCount) -> str:
        if isinstance(item, AnalyticsTypeCount):
            return item.type
        return item.action

    def _first_count(self, counts: dict[str, int], aliases: tuple[str, ...]) -> int:
        for alias in aliases:
            if alias in counts:
                return counts[alias]
        return 0

    def _format_status(self, value: str) -> str:
        words = value.replace("_", " ").split()
        return " ".join(word[:1].upper() + word[1:] for word in words) if words else "Unknown"
