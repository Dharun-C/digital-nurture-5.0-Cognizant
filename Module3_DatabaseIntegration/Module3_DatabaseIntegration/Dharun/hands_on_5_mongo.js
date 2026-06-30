// ============================================================
// HANDS-ON 5 [Intermediate] - MongoDB
// Document Modelling, CRUD & Aggregation | Database: college_nosql
// NOTE: Run these in mongosh or paste into Compass's shell tab.
// (This sandbox has no MongoDB server installed - run this on
// your own machine with MongoDB Community Server running.)
// ============================================================

use college_nosql;

// ============================================================
// TASK 1: Create the Collection and Insert Documents
// ============================================================

// Step 61-62: create feedback collection, insert >=10 documents
// (3+ for CS101, 2+ for CS102, varied ratings/tags/semesters)
db.feedback.insertMany([
  { student_id: 1, course_code: 'CS101', semester: '2022-ODD', rating: 5,
    comments: 'Excellent teaching. Would recommend.',
    tags: ['challenging', 'well-structured', 'good-examples'],
    submitted_at: new Date('2022-11-30T10:15:00Z'),
    attachments: [{ filename: 'notes.pdf', size_kb: 240 }] },

  { student_id: 2, course_code: 'CS101', semester: '2022-ODD', rating: 4,
    comments: 'Good pace, clear explanations.',
    tags: ['well-structured', 'good-examples'],
    submitted_at: new Date('2022-11-28T09:00:00Z'),
    attachments: [{ filename: 'slides.pdf', size_kb: 180 }] },

  { student_id: 5, course_code: 'CS101', semester: '2022-ODD', rating: 3,
    comments: 'Decent, but assignments were tough.',
    tags: ['challenging'],
    submitted_at: new Date('2022-12-01T14:30:00Z') }, // Step 63: no attachments field

  { student_id: 1, course_code: 'CS102', semester: '2022-ODD', rating: 5,
    comments: 'Loved the database modules.',
    tags: ['well-structured', 'good-examples', 'practical'],
    submitted_at: new Date('2022-11-29T11:00:00Z'),
    attachments: [{ filename: 'erd.png', size_kb: 95 }] },

  { student_id: 5, course_code: 'CS102', semester: '2022-ODD', rating: 4,
    comments: 'Solid course overall.',
    tags: ['practical'],
    submitted_at: new Date('2022-12-02T08:45:00Z'),
    attachments: [{ filename: 'queries.sql', size_kb: 12 }] },

  { student_id: 3, course_code: 'EC101', semester: '2021-ODD', rating: 2,
    comments: 'Too theoretical for my taste.',
    tags: ['challenging', 'theoretical'],
    submitted_at: new Date('2021-11-15T10:00:00Z'),
    attachments: [{ filename: 'circuit_notes.pdf', size_kb: 300 }] },

  { student_id: 6, course_code: 'EC101', semester: '2021-EVEN', rating: 3,
    comments: 'Improved a lot in the second half.',
    tags: ['challenging'],
    submitted_at: new Date('2022-05-20T13:00:00Z'),
    attachments: [{ filename: 'lab_report.pdf', size_kb: 150 }] },

  { student_id: 4, course_code: 'ME101', semester: '2023-ODD', rating: 4,
    comments: 'Engaging lab sessions.',
    tags: ['practical', 'well-structured'],
    submitted_at: new Date('2023-11-10T16:20:00Z'),
    attachments: [{ filename: 'lab_manual.pdf', size_kb: 420 }] },

  { student_id: 7, course_code: 'ME101', semester: '2023-ODD', rating: 1,
    comments: 'Pace was too fast, hard to keep up.',
    tags: ['challenging'],
    submitted_at: new Date('2023-11-12T09:30:00Z') },

  { student_id: 8, course_code: 'CS103', semester: '2022-ODD', rating: 5,
    comments: 'Best course this semester. Great examples.',
    tags: ['well-structured', 'good-examples', 'practical'],
    submitted_at: new Date('2022-12-03T17:00:00Z'),
    attachments: [{ filename: 'project.zip', size_kb: 850 }] },

  { student_id: 6, course_code: 'EC101', semester: '2021-EVEN', rating: 2,
    comments: 'Needs better study material.',
    tags: ['challenging', 'theoretical'],
    submitted_at: new Date('2022-05-22T10:00:00Z'),
    attachments: [{ filename: 'feedback_attachment.pdf', size_kb: 60 }] }
]);

// Step 64: verify insert count (expect >= 10)
db.feedback.countDocuments();


// ============================================================
// TASK 2: CRUD Operations
// ============================================================

// Step 65: READ - all feedback with rating 5
db.feedback.find({ rating: 5 });

// Step 66: READ - CS101 feedback where tags contains 'challenging'
db.feedback.find({ course_code: 'CS101', tags: 'challenging' });
// (Simple value match against an array field works directly in MongoDB -
// $elemMatch is only needed when matching multiple conditions on the
// SAME array element within a sub-document array.)

// Step 67: READ - projection: only student_id, course_code, rating (exclude _id)
db.feedback.find({}, { student_id: 1, course_code: 1, rating: 1, _id: 0 });

// Step 68: UPDATE - add needs_review:true to all docs with rating < 3
db.feedback.updateMany(
  { rating: { $lt: 3 } },
  { $set: { needs_review: true } }
);

// Step 69: UPDATE - push 'reviewed' tag into docs where needs_review is true
db.feedback.updateMany(
  { needs_review: true },
  { $push: { tags: 'reviewed' } }
);

// Step 70: DELETE - remove docs where semester is '2021-EVEN'
db.feedback.deleteMany({ semester: '2021-EVEN' });


// ============================================================
// TASK 3: Aggregation Pipeline
// ============================================================

// Step 71: filter to 2022-ODD, group by course_code (avg rating + count), sort desc
db.feedback.aggregate([
  { $match: { semester: '2022-ODD' } },
  { $group: {
      _id: '$course_code',
      avg_rating: { $avg: '$rating' },
      total_feedback: { $sum: 1 }
  }},
  { $sort: { avg_rating: -1 } }
]);

// Step 72: extend with $project - rename avg_rating to average_rating, round to 1 decimal
db.feedback.aggregate([
  { $match: { semester: '2022-ODD' } },
  { $group: {
      _id: '$course_code',
      avg_rating: { $avg: '$rating' },
      total_feedback: { $sum: 1 }
  }},
  { $project: {
      course_code: '$_id',
      _id: 0,
      average_rating: { $round: ['$avg_rating', 1] },
      total_feedback: 1
  }},
  { $sort: { average_rating: -1 } }
]);

// Step 73: $unwind tags, group by tag, count occurrences, sort desc (tag frequency leaderboard)
db.feedback.aggregate([
  { $unwind: '$tags' },
  { $group: { _id: '$tags', count: { $sum: 1 } } },
  { $sort: { count: -1 } }
]);

// Step 74: index on course_code, verify IXSCAN is used
db.feedback.createIndex({ course_code: 1 });
db.feedback.find({ course_code: 'CS101' }).explain('executionStats');
// Check the explain output's `executionStats.executionStages.stage` (or nested
// inputStage) - it should read "IXSCAN", not "COLLSCAN", confirming the new
// index on course_code is actually being used by the query planner.
